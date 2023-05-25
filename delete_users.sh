#!/bin/bash

# List of users to be deleted
USERS=("user1" "user2" "user3")

# Loop through each user and delete
for user in "${USERS[@]}"; do
    # Check if the user exists
    if id "$user" >/dev/null 2>&1; then
        # Delete the user's home directory
        rm -rf "/home/$user"
        
        # Delete the user
        userdel -r "$user"
        
        echo "User '$user' deleted successfully."
    else
        echo "User '$user' does not exist."
    fi
done
