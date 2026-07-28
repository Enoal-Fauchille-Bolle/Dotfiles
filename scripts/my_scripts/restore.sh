ORIGIN="/media/$USER/MyDisk/Backup"

sudo rsync -avh --progress --copy-links \
  "$ORIGIN"/Documents \
  "$ORIGIN"/Downloads \
  "$ORIGIN"/Pictures \
  "$ORIGIN"/Videos \
  "$ORIGIN"/my_scripts \
  "$ORIGIN"/Projects \
  ~/ \
  --exclude "node_modules" \
  --exclude "target" \
  --exclude "dist" \
  --exclude ".venv" \
    2> rsync-errors.log

echo "--- Errors ---"
cat rsync-errors.log
