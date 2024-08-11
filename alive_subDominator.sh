#!/bin/bash

# Check if a file with domains was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <domain_file>"
    exit 1
fi

DOMAIN_FILE=$1
WORDLIST="/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt"
ALIVE_DOMAINS="alive_domains.txt"

# Function to find subdomains using dig
find_subdomains() {
    local domain=$1
    echo "Finding subdomains for $domain..."

    while read -r subdomain; do
        full_domain="$subdomain.$domain"
        
        # Check if the subdomain resolves
        if dig +short "$full_domain" > /dev/null; then
            echo "$full_domain"
        fi
    done < "$WORDLIST"
}

# Get subdomains using cert.sh
get_subdomains_certsh() {
    local domain=$1
    echo "Fetching subdomains from cert.sh for $domain..."
    curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u
}

# Check if subdomains are alive using curl
check_alive_domains() {
    echo "Checking which subdomains are alive..."
    while read -r domain; do
        if curl -s --head --request GET "$domain" | grep "200 OK" > /dev/null; then
            echo "$domain is alive"
            echo "$domain" >> "$ALIVE_DOMAINS"
        fi
    done < subdomains.txt
}

# Process each domain in the file
process_domains() {
    while read -r domain; do
        echo "Processing domain: $domain"
        all_subdomains "$domain" | tee subdomains.txt
        check_alive_domains
        echo "---------------------------------------------"
    done < "$DOMAIN_FILE"
}

# Combining results from different methods
all_subdomains() {
    local domain=$1
    find_subdomains "$domain"
    get_subdomains_certsh "$domain"
}

# Run the function for all domains in the file
process_domains

echo "Alive domain check completed. Results saved in $ALIVE_DOMAINS"
