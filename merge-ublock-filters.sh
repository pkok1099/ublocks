#!/usr/bin/env bash
set -e

REPO_API="https://api.github.com/repos/uBlockOrigin/uAssets/contents/filters"
OUT="ublock-merged.txt"
TMPDIR=$(mktemp -d)

echo "! uBlock filters merged" > $OUT
echo "! Source: uBlockOrigin/uAssets" >> $OUT
echo "! Updated: $(date -u)" >> $OUT
echo >> $OUT

# 1️⃣ Ambil semua URL RAW
urls=$(curl -s "$REPO_API" | jq -r '.[].download_url')

# 2️⃣ Download setiap file ke TMPDIR
for url in $urls; do
    curl -s "$url" -o "$TMPDIR/$(basename $url)"
done

# 3️⃣ Gabung semua file, hapus duplikat, trim empty lines
cat $TMPDIR/* | awk 'NF && !seen[$0]++' >> $OUT

# 4️⃣ Hapus TMPDIR
rm -rf $TMPDIR
