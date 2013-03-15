#!/bin/zsh
zmodload zsh/mathfunc

set -e

# parameters
#############
CRef=0
hue_angle=0
CDefault='DD9A3A'
opt=$1
Hue=$2
png_folders=(16x16 22x22 32x32)
svg_folders=(scalable)
folders=($png_folders $svg_folders)

# absolute path dirs
main_dir=$(pwd)
image_dir_in=$(dirname $main_dir)
image_dir_out="$image_dir_in/cache"

# paths for images to colorize
images_paths=(
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

composite_images_paths=(actions/folder-new.png)
part1_images_paths=(places/folder.png)
part2_images_paths=(stock/flash_folder.png)

# Default color scheme for svg
# top color 
#729fcf
# buttom color
#6194cb
# border buttom color
#3465a4
default_color_scheme=($(grep -o '#[1-9a-ZA-Z]*' default_color_scheme.xpm | cut -d'#' -f2))
set $default_color_scheme
echo "default color scheme : $default_color_scheme"
top_color=$1
buttom_color=$2
border_color=$3

# reload image path
reload() {
	cd $1
	images_paths=($(find */*.png -type f > $main_dir/image_path))
	cd $main_dir
}

color_selection() {
echo 'select the [main color] for folders images or:'
echo '[Br]=brown(default)'

read answer
case $answer in
Br)				CRef='DD9A3A'		;;
\#*)			CRef=${answer:1:6} 	;;
[a-z][a-z1-9]*)	CRef=$(grep -P "$answer\t" colormap | cut -f3 | cut -d'#' -f2) ;;
*) CRef=$CDefault	;;
esac
}

color_pick() {
# pick up colors in images
convert $image_dir_in/32x32/actions/folder.png  folder.xpm
default_color_map=($(grep -o 'c [#0-9a-ZA-Z]*"' foo.xpm | cut -d' ' -f2 | cut -d\" -f1 | grep -v 'None'))
#echo $default_color_map
}

# steps :
##########

recolor() {
convert $1 -modulate 100,100,$modulate_arg $2
}

substitute_color() {
path_in=$1
path_out=$2
cp $path_in $path_out
j=1;
set $default_color_scheme
	for i
	do
	sed -i "s/\#$i/\#$color_scheme[j]/g" $path_out
	(( j++ ))
	done
}

discolor() {
convert $1 -type GrayScaleMatte $2
}

discolor_xpm() {
# workaround to make sure than files are formated in the same way
convert $1 color_formated.xpm
discolor color_formated.xpm $2
rm color_formated.xpm
colors=($(grep -o '#[0-9a-ZA-Z]*' $2 | cut -d'#' -f2))
# workaround : convert color hexa 12 to 6 characters
set $colors
for i
do
echo ${i:0:2}${i:4:2}${i:8:2}
done
}

recolor_path() {
recolor_function=$1
shift
for folder
do
	set $images_paths
	for image_path
	do
	mkdir -p $folder/$(dirname $image_path)
		if [[ -f $image_dir_in/$folder/$image_path ]]
		then
		$recolor_function $image_dir_in/$folder/$image_path $folder/$image_path
		fi
	done
done
}

compose_images() {
for folder
do
	i=1
	set $part1_images_paths
	for image_path
	do
	composite $image_dir_in/$folder/$part2_images_paths[i] $folder/$image_path $folder/$composite_images_paths
	(( i++ ))
	done
done
}

# options
##########

case $opt in
-r)	reload '../../zen-colors/gnome-colors/22x22'	;;
-d)	CRef=$CDefault 	;;
-h)	hue_angle=$Hue	; echo "hue-value = $hue_angle";;
-g)	 ;;
'') color_selection	;;
*) exit 1	;;
esac

case $opt in
-d|-r|'')	hue_angle=$(./rotate $buttom_color $CRef)	;;
esac

case $opt in
-g) 
	color_scheme=($(discolor_xpm default_color_scheme.xpm color_scheme.xpm))
	echo "grayscale color scheme : $color_scheme"
;;
*)
	modulate_arg=$(( ( $hue_angle * 100/180 ) + 100 ))
	echo $default_color_scheme > default_color_scheme.txt
	color_scheme=($(./rotate -hue $hue_angle default_color_scheme.txt))
	substitute_color $default_color_scheme.xpm $color_scheme.xpm
	echo "new color scheme : $color_scheme"
	;;
esac

echo "convert images : $folders..."
cd $image_dir_out
rm -r -f $folders
mkdir -p $folders

case $opt in
-g)	recolor_path discolor $png_folders ;;
*)	recolor_path recolor $png_folders	;;
esac

# replace .png with .svg
images_paths=($(echo $images_paths | sed 's/.png/.svg/g'))
recolor_path substitute_color $svg_folders
compose_images $png_folders
