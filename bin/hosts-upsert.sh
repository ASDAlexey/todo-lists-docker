#!/bin/bash

# insert/update hosts entry
host_name="127.0.0.1 localhost ${URL_FRONTEND} www.${URL_FRONTEND}"

# find existing instances in the host file and save the line numbers
matches_in_hosts="$(grep -n "${host_name}" /etc/hosts | cut -f1 -d:)"

echo $host_name

if [ ! -z "$matches_in_hosts" ]
then
    echo "Updating existing hosts entry."
    # iterate over the line numbers on which matches were found
    while read -r line_number; do
        # replace the text of each line with the desired host entry
        sudo sed -i '' -e "${line_number}s/.*/${host_name} /" /etc/hosts
    done <<< "$matches_in_hosts"
else
    echo "Adding new hosts entry."
    echo "$host_name" | sudo tee -a /etc/hosts > /dev/null
fi
