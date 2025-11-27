#!/bin/bash
# mr_clean
if [ -z "$1" ]
then
  echo "Please specify a message"
else
  echo "Pulling origin..."
  git stash
  git pull origin $(git rev-parse --abbrev-ref HEAD)
  git stash pop
  echo "Adding files to commit..."
  git add .
  echo "Commiting..."
  git commit -m "$1"
  echo "Pushing..."
  git push origin $(git rev-parse --abbrev-ref HEAD)
  echo "Done !!!"
fi
