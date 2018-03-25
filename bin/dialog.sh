#!/usr/bin/env bash

echo -ne "\n\033[1;mAre you sure to proceed?\033[0m\n"
select yn in "Yes" "No"; do
        case $yn in
                Yes ) exit 0;;
                No ) exit 1;;
        esac
done
