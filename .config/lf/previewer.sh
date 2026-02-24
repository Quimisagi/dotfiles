#!/usr/bin/env bash
file=$1
w=$2
h=$3
x=$4
y=$5

# Check the file's mime type
filetype="$(file -Lb --mime-type "$file")"

case "$filetype" in
    image/*)
        # Draw standard images
        kitty +kitten icat --silent --stdin no --transfer-mode file --place "${w}x${h}@${x}x${y}" "$file" < /dev/null > /dev/tty
        exit 1
        ;;
    
    video/*)
        CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/lf"
        mkdir -p "$CACHE"
        thumb="$CACHE/$(echo -n "$file" | md5sum | awk '{print $1}').jpg"
        
        if [ ! -f "$thumb" ]; then
            ffmpegthumbnailer -i "$file" -o "$thumb" -s 0 -q 8 -t 10%
        fi
        
        kitty +kitten icat --silent --stdin no --transfer-mode file --place "${w}x${h}@${x}x${y}" "$thumb" < /dev/null > /dev/tty
        exit 1
        ;;
        
    application/pdf)
        CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/lf"
        mkdir -p "$CACHE"
        thumb="$CACHE/$(echo -n "$file" | md5sum | awk '{print $1}').jpg"
        
        if [ ! -f "$thumb" ]; then
            # -f 1 -l 1 extracts only the first page
            # -singlefile prevents pdftoppm from appending page numbers to the filename
            # -jpeg converts it to a fast-loading JPEG
            pdftoppm -jpeg -f 1 -l 1 -singlefile "$file" "${thumb%.jpg}"
        fi
        
        kitty +kitten icat --silent --stdin no --transfer-mode file --place "${w}x${h}@${x}x${y}" "$thumb" < /dev/null > /dev/tty
        exit 1
        ;;
esac
# Fallback for plain text files
cat "$file"
