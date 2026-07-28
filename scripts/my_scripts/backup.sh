DEST="/run/media/$USER/MyDisk/Backup"
mkdir -p "$DEST"

sudo rsync -avh --progress --copy-links \
  ~/Documents \
  ~/Downloads \
  ~/Delivery \
  ~/Pictures \
  ~/Videos \
  ~/my_scripts \
  ~/Projects \
  ~/.ssh \
  "$DEST"/ \
  --exclude "node_modules" \
  --exclude "target" \
  --exclude "dist" \
  --exclude ".venv" \
    2> rsync-errors.log

echo "--- Errors ---"
cat rsync-errors.log
