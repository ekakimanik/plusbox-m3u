#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1

curl -s "https://plusbox.tv/api/catalog/channels" -o channels.json
echo "#EXTM3U" > new.m3u

jq -r '.[] | select(.active=="1") | [.ch_name,.category,.img_url] | @tsv' channels.json |
while IFS=$'\t' read -r name cat logo; do
  stream=$(echo "$name" | tr -d ' ')
  url=$(curl -s "https://plusbox.tv/token.php?stream=$stream" \
        | grep -oE "https://plusbox\.tv:8080/[^\"' <>]+\.m3u8\?token=[^\"' <>]+" | head -1)
  [ -z "$url" ] && echo "SKIP: $name" >&2 && continue
  echo "#EXTINF:-1 tvg-logo=\"$logo\" group-title=\"$cat\",$name" >> new.m3u
  echo "$url" >> new.m3u
  sleep 0.2
done

if [ "$(grep -c '^http' new.m3u)" -gt 0 ]; then
  mv new.m3u playlist.m3u
  rm -f channels.json
  git add playlist.m3u update.sh
  git commit -m "update $(date +%F-%H:%M)" && git push
  echo "DONE: $(grep -c '^http' playlist.m3u) channels"
else
  echo "কোনো চ্যানেল পাওয়া যায়নি"
fi
