#!/usr/bin/env bash
set -e

# Daftar API Repositori GitHub (tambah URL API di sini)
REPOS=(
    "https://api.github.com/repos/uBlockOrigin/uAssets/contents/filters"
    "https://api.github.com/repos/AdguardTeam/AdguardFilters/contents/BaseFilter/sections"
    "https://api.github.com/repos/AdguardTeam/AdguardFilters/contents/SpywareFilter/sections"
    "https://api.github.com/repos/AdguardTeam/AdguardFilters/contents/AnnoyancesFilter/sections"
)

OUT="ublock-merged.txt"
TMPDIR=$(mktemp -d)

# 1. Header File
{
    echo "! uBlock filters merged"
    echo "! Sources: uBlockOrigin & AdGuard"
    echo "! Updated: $(date -u)"
    echo ""
} > "$OUT"

# 2. Loop melalui setiap Repo
for REPO_API in "${REPOS[@]}"; do
    echo "Processing: $REPO_API"
    
    # Ambil URL download untuk file .txt saja
    urls=$(curl -sL "$REPO_API" | jq -r '.[] | select(.type=="file" and (.name | endswith(".txt"))) | .download_url')

    for url in $urls; do
        # Nama file unik menggunakan timestamp agar tidak bentrok antar repo
        filename="$(basename "$url")_$(date +%s%N).tmp"
        curl -sL "$url" -o "$TMPDIR/$filename" &
    done
done

# Tunggu semua proses download selesai
wait

# 3. Gabungkan, bersihkan komentar duplikat, dan hapus baris kosong
# 'grep -v' membuang baris yang diawali '!' kecuali di header utama kita
cat "$TMPDIR"/*.tmp | grep -v '^!' | awk 'NF && !seen[$0]++' >> "$OUT"

# 4. Cleanup
rm -rf "$TMPDIR"
echo "Done! Merged into $OUT"
