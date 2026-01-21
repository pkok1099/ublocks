#!/usr/bin/env bash
set -e

# Daftar API Repositori yang SUDAH DIVALIDASI
REPOS=(
    "https://api.github.com/repos/uBlockOrigin/uAssets/contents/filters"
    "https://api.github.com/repos/AdguardTeam/AdguardFilters/contents/BaseFilter/sections"
    "https://api.github.com/repos/AdguardTeam/AdguardFilters/contents/SpywareFilter/sections"
    # Perbaikan: Annoyances dipecah ke kategori spesifik agar valid
    "https://api.github.com/repos/AdguardTeam/AdguardFilters/contents/AnnoyancesFilter/Popups/sections"
    "https://api.github.com/repos/AdguardTeam/AdguardFilters/contents/AnnoyancesFilter/Cookies/sections"
)


OUT="ublock-merged.txt"
TMPDIR=$(mktemp -d)

# Header
{
    echo "! uBlock filters merged"
    echo "! Updated: $(date -u)"
    echo ""
} > "$OUT"

for REPO_API in "${REPOS[@]}"; do
    echo "Processing: $REPO_API"
    
    # Request ke GitHub API
    response=$(curl -sL "$REPO_API")
    
    # Deteksi Tipe Respon (Array/Object/Error)
    json_type=$(echo "$response" | jq -r 'type')
    
    if [ "$json_type" == "array" ]; then
        # KASUS 1: Folder (berisi banyak file)
        # Ambil semua file .txt
        urls=$(echo "$response" | jq -r '.[] | select(.type=="file" and (.name | endswith(".txt"))) | .download_url')
        
    elif [ "$json_type" == "object" ]; then
        # KASUS 2: Single File atau Error Message
        msg=$(echo "$response" | jq -r '.message // empty')
        
        if [ ! -z "$msg" ] && [ "$msg" != "null" ]; then
            echo "  ❌ Error: $msg"
            urls=""
        else
            urls=$(echo "$response" | jq -r '.download_url // empty')
        fi
    else
        urls=""
    fi

    # Eksekusi Download
    if [ ! -z "$urls" ]; then
        for url in $urls; do
            filename="$(basename "$url")_$(date +%s%N).tmp"
            # Download background
            curl -sL "$url" -o "$TMPDIR/$filename" &
        done
        echo "  ✅ Downloading files..."
    fi
done

# Tunggu semua download selesai
wait

# Gabung file
echo "Merging files..."
if ls "$TMPDIR"/*.tmp >/dev/null 2>&1; then
    # Gabung + Hapus '!' comments + Hapus Empty Lines + Hapus Duplicate Lines
    cat "$TMPDIR"/*.tmp | grep -v '^!' | awk 'NF && !seen[$0]++' >> "$OUT"
    echo "Done! Saved to $OUT"
    echo "Total lines: $(wc -l < $OUT)"
else
    echo "Warning: No files downloaded."
fi

# Bersihkan
rm -rf "$TMPDIR"
