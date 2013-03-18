#!/bin/zsh
zmodload zsh/mathfunc

# dependencies : imagemagick >= v6.5.3, libpng, librsvg, libxml
set -e

# parameters
#############
hue_angle=0
CRef=0
png_subdirs=(16x16 22x22 32x32)
svg_subdirs=(scalable)
SUBDIRS=($png_subdirs $svg_subdirs)

make_paths() {
paths=''
for folder
do
paths_folder=($(echo -e $(echo $recolor_paths|sed 's/ /\\n/g')| sed "s/^/$folder\//g"))
paths=($paths $paths_folder)
done
echo $paths
}

color_pick() {
# pick up colors in images
convert 32x32/actions/folder.png  folder.xpm
default_color_map=($(grep -o 'c [#0-9a-ZA-Z]*"' foo.xpm | cut -d' ' -f2 | cut -d\" -f1 | grep -v 'None'))
#echo $default_color_map
}

# steps :
##########

recolor() {
convert $1 -modulate 100,100,$modulate_arg $1
}

substitute_color() {
image=$1
j=1;
set $default_color_scheme
	for i
	do
	sed -i "s/\#$i/\#$color_scheme[j]/g" $image
	(( j++ ))
	done
}

discolor() {
convert $1 -type GrayScaleMatte $1
}

discolor_xpm() {
# workaround to make sure than files are formated in the same way
convert $1 $1
discolor $1 $1
colors=($(grep -o '#[0-9a-ZA-Z]*' $1 | cut -d'#' -f2))
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
for image_path
do
	if [[ -f $image_path ]]
	then
	$recolor_function $image_path
	fi
done
}

compose_images() {
i=1
for composite_path
do
composite $part2_paths[i] $part1_paths[i] $composite_path
(( i++ ))
done
}

# options
##########

color_value() {
case $1 in;
Br)				CRef='DD9A3A'	;;
\#*)			CRef=${1:1:6} 	;;
[a-z][a-z1-9]*)	CRef=$(grep -p "$1\t" colormap | cut -f3 | cut -d'#' -f2) ;;
*) echo "Invalid color"; exit 1	;;
esac
}

show_help() {
echo "usage : [OPTIONS] [ARG] <dir-in> <dir-out>
OPTIONS :
	-p <paths-lists> : file contain list of pathname parameters
	-O : compose icons with composite function
ARGUMENTS :
	-c <color> : by name or hexadecimal <Br>=Brown
	-G : convert image to grayscale
	-h <hue-angle> : use hue angle instead of color name"
}

# default recolor function for png files
recolor_png=recolor
path_lists='dir'
composite='FALSE'
while getopts c:CGh:Op: opt
do
	case $opt in
	c)	arg=c; color_value $OPTARG ;;
	G)	arg=G; recolor_png=discolor	;;
	h)	arg=h; hue_angle=$OPTARG ;;
	O)	composite='TRUE' ;;
	p)	path_lists='file'; source $OPTARG ;;
	\?)	show_help; exit 1 ;;
	esac
done

# shift to <dir-in> <dir-out>
if [[ $OPTIND == 1 ]]
then
 show_help; exit 1;
fi

MAIN_DIR=$(pwd)
shift $(($OPTIND -1))
if [[ $2 == '' ]]
then
	if [[ $1 == '' ]]
	then
	IMAGE_DIR_OUT=$MAIN_DIR/cache
	else
	IMAGE_DIR_OUT=$1
	fi
else
	IMAGE_DIR_IN=$1
	IMAGE_DIR_OUT=$2
	echo $SUBDIRS
	set $SUBDIRS
	for subdir
	do
	rm -r -f $IMAGE_DIR_OUT/$subdir
	cp -r -f $IMAGE_DIR_IN/$subdir $IMAGE_DIR_OUT
	done
fi

case $arg in
c|G|h)
	# Default color scheme for svg
	# top color				#729fcf
	# buttom color			#6194cb
	# border buttom color	#3465a4
	default_color_scheme=($(grep -o '#[1-9a-ZA-Z]*' default_color_scheme.xpm | cut -d'#' -f2))
	set $default_color_scheme
	echo "default color scheme : $default_color_scheme"
	top_color=$1; buttom_color=$2; border_color=$3
	cp default_color_scheme.xpm color_scheme.xpm
esac

case $arg in
c)	hue_angle=$(./rotate $buttom_color $CRef) ;;
esac

case $arg in
G)
	color_scheme=($(discolor_xpm color_scheme.xpm))
	echo "grayscale color scheme : $color_scheme"
	;;
c|h)
	modulate_arg=$(( ( $hue_angle * 100/180 ) + 100 ))
	echo $default_color_scheme > default_color_scheme.txt
	color_scheme=($(./rotate -hue $hue_angle default_color_scheme.txt))
	substitute_color color_scheme.xpm
	echo "new color scheme : $color_scheme"
esac

cd $IMAGE_DIR_OUT
case $arg in
c|G|h)
echo "convert images : $SUBDIRS..."
	if [[ $path_lists == 'file' ]]
	then
		recolor_paths=$RECOLOR_PATHS
		png_recolor_paths=($(make_paths $png_subdirs))
		svg_recolor_paths=($(make_paths $svg_subdirs | sed 's/.png/.svg/g'))
	else
	#elif [[ $path_lists == 'dir' ]]
		svg_recolor_paths=($(find **/*.svg -type f))
		png_recolor_paths=($(find **/*.png -type f))
	fi

	recolor_path $recolor_png $png_recolor_paths
	recolor_path substitute_color $svg_recolor_paths
esac

if [[ $composite == 'TRUE' ]]
then
	if [[ $path_lists == 'file' ]]
	then
	echo "compose images : $png_subdirs..."
	recolor_paths=$COMPOSITE_PATHS
	composite_paths=($(make_paths $png_subdirs))
	recolor_paths=$PART1_PATHS
	part1_paths=($(make_paths $png_subdirs))
	recolor_paths=$PART2_PATHS
	part2_paths=($(make_paths $png_subdirs))
	else
	#elif [[ $path_lists == 'dir' ]]
	echo "compose images : $image_dir..."
	part1_paths=($(find **/*.png -type f))
	composite_paths=$image_dir
	part2_dir=stock
	cd $part2_dir
	part2_paths=($(find **/*.png -type f))
	cd ../$image_dir
	fi
	compose_images $composite_paths
fi
