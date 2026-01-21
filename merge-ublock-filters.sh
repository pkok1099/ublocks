#!/usr/bin/env bash
set -e

REPO_API="https://api.github.com/repos/uBlockOrigin/uAssets/contents/filters"
OUT="ublock-merged.txt"
TMPDIR=$(mktemp -d)

# Header file
{
    echo "! uBlock filters merged"
    echo "! Source: uBlockOrigin/uAssets"
    echo "! Updated: $(date -u)"
    echo ""
} > "$OUT"

# 1. Ambil URL RAW (Filter hanya file .txt agar tidak mengambil folder/sub-item)
urls=$(curl -sL "$REPO_API" | jq -r '.[] | select(.type=="file" and (.name | endswith(".txt"))) | .download_url')

# 2. Download secara paralel (opsional, tapi lebih cepat)
for url in $urls; do
    # -L untuk mengikuti redirect, -s untuk silent
    curl -sL "$url" -o "$TMPDIR/$(basename "$url")" &
done
wait # Menunggu semua proses download selesai

# 3. Gabungkan dengan Filter yang lebih cerdas
# - Menghapus komentar duplikat (opsional)
# - Menghapus baris kosong
# - Menghapus duplikat baris
cat "$TMPDIR"/*.txt | grep -v '^!' | awk 'NF && !seen[$0]++' >> "$OUT"

# Bersihkan
rm -rf "$TMPDIR"
