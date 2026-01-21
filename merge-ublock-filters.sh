#!/usr/bin/env bash
set -e

REPO_API="https://api.github.com/repos/uBlockOrigin/uAssets/contents/filters"
OUT="ublock-merged.txt"
TMPDIR=$(mktemp -d)

echo "! uBlock filters merged" > $OUT
echo "! Source: uBlockOrigin/uAssets" >> $OUT
echo "! Updated: $(date -u)" >> $OUT
echo >> $OUT

# Ambil semua URL RAW
urls=$(curl -s "$REPO_API" | jq -r '.[].download_url')

# Download setiap file ke TMPDIR
for url in $urls; do
    curl -s "$url" -o "$TMPDIR/$(basename $url)"
done

# Gabung semua file, hapus duplikat & empty line
cat $TMPDIR/* | awk 'NF && !seen[$0]++' >> $OUT

# Hapus TMPDIR
rm -rf $TMPDIR
