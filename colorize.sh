#!/bin/zsh
zmodload zsh/mathfunc

set -e

# parameters
#############
reload=$1
size=(16x16 22x22 32x32)
folders=($size scalable)
echo 'select the main color for folders icons : [color-name], [ hue-value ] or:'
echo '[Br]=brown(default)'

read answer
CRef=0
HueRef=0
case $answer in
Br)				CRef='DD9A3A'		;;
\#*)			CRef=${answer:1:6} 	;;
[a-z][a-z1-9]*)	CRef=$(grep -P "$answer\t" colormap | cut -f3 | cut -d'#' -f2) ;;
[1-9]*) 		HueRef=$answer 		;;
*) CRef='DD9A3A'	;;
esac

# absolute path dirs
main_dir=$(pwd)
icon_dir_in=$(dirname $main_dir)
icon_dir_out="$icon_dir_in/cache"

# paths for icons to colorize
icons_paths=(
actions/add-folder-to-archive.png
actions/document-open.png
actions/folder-copy.png
actions/folder-move.png
actions/folder-new.png
apps/fusion-icon.png
apps/gnome-panel-workspace-switcher.png
apps/vinagre.png
emblems/emblem-desktop.png
places/folder-documents.png
places/folder-downloads.png
places/folder-music.png
places/folder-pictures.png
places/folder.png
places/folder-publicshare.png
places/folder-remote.png
places/folder-videos.png
places/user-desktop.png
places/user-home.png
status/folder-open.png
)

composite_icons_paths=(actions/folder-new.png)
part1_icons_paths=(places/folder.png)
part2_icons_paths=(stock/flash_folder.png)

# Default color scheme for svg
# top color 
#729fcf
# buttom color
#6194cb
# border buttom color
#3465a4

# steps :

default_color_scheme=($(grep -o '#[1-9a-ZA-Z]*' default_color_scheme.xpm | cut -d'#' -f2))
set $default_color_scheme
top_color=$1
buttom_color=$2
border_color=$3
echo $default_color_scheme

# reload icon path
if [[ $reload == -r ]]
then
	cd '../../zen-colors/gnome-colors/22x22'
	icons_paths=($(find */*.png -type f > $main_dir/icon_path))
	cd $main_dir
fi

color_pick() {
# pick up colors in images
convert $icon_dir_in/32x32/actions/folder.png  folder.xpm
default_color_map=($(grep -o 'c [#0-9a-ZA-Z]*"' foo.xpm | cut -d' ' -f2 | cut -d\" -f1 | grep -v 'None'))
#echo $default_color_map
}

# return hue_angle from base color to ref color
if [[ $CRef == 0 ]]
then
hue_angle=$HueRef
else
hue_angle=$(./rotate $buttom_color $CRef)
fi
modulate_arg=$(( ( $hue_angle * 100/180 ) + 100 ))

echo "convert svg color scheme..."
echo $default_color_scheme > default_color_scheme.txt
color_scheme=($(./rotate -hue $hue_angle default_color_scheme.txt))
j=1;
cp default_color_scheme.xpm color_scheme.xpm
set $default_color_scheme
for i
do
sed -i "s/\#$i/\#$color_scheme[$j]/g" color_scheme.xpm
echo $i $color_scheme[$j]
(( j++ ))
done
#convert default_color_scheme.xpm -modulate 100,100,$modulate_arg color_scheme.xpm
#cs=($(grep -o '#[1-9a-ZA-Z]*' color_scheme.xpm | cut -d'#' -f2))
# convert color code exa to six characters

hexa6cv() {
for i
do
echo ${i:0:2}${i:4:2}${i:8:2}
done
}
#color_scheme=($(hexa6cv $cs))
#echo $color_scheme

convert_png_icons() {
convert $icon_dir_in/$folder/$icon_path -modulate 100,100,$modulate_arg $folder/$icon_path
}

convert_svg_icons() {
cp $icon_dir_in/$folder/${icon_path%.*}.svg $folder/${icon_path%.*}.svg
j=1;
set $default_color_scheme
	for i
	do
	sed -i "s/\#$i/\#$color_scheme[j]/g" $folder/${icon_path%.*}.svg
	(( j++ ))
	done
}

echo "convert icons folders $folders..."
cd $icon_dir_out
rm -r -f $folders
mkdir -p $folders
set $folders
for folder
do
	set $icons_paths
	for icon_path
	do
	mkdir -p $folder/$(dirname $icon_path)
		if [[ $folder == 'scalable' ]]
		then
			if [[ -f $icon_dir_in/$folder/${icon_path%.*}.svg ]]
			then
			convert_svg_icons $icon_path
			fi
		else
			if [[ -f $icon_dir_in/$folder/$icon_path ]]
			then
			convert_png_icons $icon_path
			fi
		fi
	done
done

compose_icons() {
for i
do
	k=1
	set $part1_icons_paths
	for j
	do
	composite $icon_dir_in/$i/$part2_icons_paths[k] $i/$j $i/$composite_icons_paths
	(( k++ ))
	done
done
}

compose_icons $size

