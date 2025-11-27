# !/bin/bash

# This script is used to pull while having a commit to push.
# It saves the last commit message, resets the commit, pulls the latest changes,
# and then re-adds the files to the commit with the saved message.

# It is useful when your mate pushed before you

git log -1 --pretty=%B > saved_commit_message.txt
git reset --soft HEAD~1
git stash
git pull
git stash pop
echo "I let you stage your changes"
echo "Just make sure there is no conflicts"
echo "You can now commit your changes with the old commit message"
echo "Here is your old commit message:"
cat saved_commit_message.txt
rm saved_commit_message.txt

# Made for Tom Feldkamp ;)
