#!/bin/bash

# Check if a file is provided as an argument
if [ $# -lt 2 ]; then
    echo "Usage: $0 <subdomains_file> <output_file>"
    exit 1
fi

# Read the file containing subdomains
subdomains_file=$1
output_file=$2

# Check if the subdomains file exists
if [ ! -f "$subdomains_file" ]; then
    echo "Subdomains file not found!"
    exit 1
fi

# Clear the output file if it exists, or create a new one
> "$output_file"

# Loop through each subdomain in the file
while IFS= read -r subdomain; do
    # Resolve the IP address
    ip_address=$(dig +short "$subdomain" | tail -n1)

    # Check if dig returned an IP address
    if [ -n "$ip_address" ]; then
        echo "$subdomain: $ip_address" >> "$output_file"
    fi
done < "$subdomains_file"

echo "Valid subdomain resolutions have been saved to $output_file"
