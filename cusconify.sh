#!/bin/sh

# 1st parameter: filename
# 2nd parameter (optional): x coordinate to get background color from
# 3rd parameter (optional): y coordinate to get background color from
# 4th parameter (optional): fuzz percentage for background
# 5th parameter (optional): fuzz percentage for trimming
# 6th parameter (optional): floodfill or replace 

filename="$1"
new_file="new_$filename"

print_background() {
    echo "Colors around the edge of $1 to get the background color"
    for x in 0 256 512
    do
        for y in 0 256 512
        do
            if [ $x != 256 ] || [ $y != 256 ]; then
                magick $1 -format "Color at ($x,$y) %[pixel:u.p{$x,$y}]\n" info:
            fi
        done
    done
}

echo "Resize $filename to 512x512"
magick $filename -resize 512x512! $new_file

echo
print_background $filename

echo
echo "Remove background"
if [ $6 = "replace" ]; then
    magick $new_file -fill none -fuzz ${4:-25}% -draw "color ${2:-0},${3:-0} replace" "no_bg_$new_file"
else
    magick $new_file -fill none -fuzz ${4:-25}% -draw "color ${2:-0},${3:-0} floodfill" "no_bg_$new_file"
fi

echo "Trim transparent border"
magick "no_bg_$new_file" -fuzz ${5:-75}% -trim "trimmed_$new_file"

# resize preserves the aspect ratio, so the longest edge is now 450px
# https://imagemagick.org/Usage/resize/
echo "Resize trimmed image so longest side is 450px"
magick "trimmed_$new_file" -resize 450x450 "450_$new_file"

echo "Put 450px trimmed image in center of 512x512 transparent image"
magick "450_$new_file" -background transparent -gravity center -extent 512x512 "aio_$new_file"


echo "Generate icon with black borders"
magick "aio_$new_file" -bordercolor none -border 12 -background black -alpha background -channel A -blur 12x12 -level 0,5% "bordered_$new_file"
