#!/bin/zsh
zmodload zsh/mathfunc

set -e

# parameters
#############
hue_angle=0
CRef=0
png_folders=(16x16 22x22 32x32)
svg_folders=(scalable)
folders=($png_folders $svg_folders)

# absolute path dirs
main_dir=$(pwd)

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
for image_path
do
mkdir -p $(dirname $image_path)
	if [[ -f $image_dir_in/$image_path ]]
	then
	$recolor_function $image_dir_in/$image_path $image_path
	fi
done
}

compose_images() {
i=1
for composite_path
do
mkdir -p $(dirname $composite_path)
composite $image_dir_in/$part2_paths[i] $part1_paths[i] $composite_path
(( i++ ))
done
}

# options
##########

color_value() {
case $1 in;
Br)	CRef='DD9A3A'	;;
\#*)	cref=${1:1:6} 	;;
[a-z][a-z1-9]*)	cref=$(grep -p "$1\t" colormap | cut -f3 | cut -d'#' -f2) ;;
*) echo "Invalid color"; exit 1	;;
esac
}

show_help() {
echo "usage : [OPTIONS] [ARG] <dir-in> <dir-out>
OPTIONS :
  -p <paths-lists> : file contain list of pathname parameters
ARGUMENTS :
  -c <color> : by name or hexadecimal <Br>=Brown  
  -G : convert image to grayscale
  -h <hue-angle> : use hue angle instead of color name
  -O : compose icons with composite function"
}

#default recolor function for png files
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

shift $(($OPTIND -1))
if [[ $1 == '' ]]
then
image_dir_in="$(dirname $main_dir)"
image_dir_out="$image_dir_in/cache"
else
image_dir_in=$1
image_dir_out=$2
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
esac

case $arg in
c)	hue_angle=$(./rotate $buttom_color $CRef) ;;
esac

case $arg in
G)
	color_scheme=($(discolor_xpm default_color_scheme.xpm color_scheme.xpm))
	echo "grayscale color scheme : $color_scheme"
	;;
c|h)
	modulate_arg=$(( ( $hue_angle * 100/180 ) + 100 ))
	echo $default_color_scheme > default_color_scheme.txt
	color_scheme=($(./rotate -hue $hue_angle default_color_scheme.txt))
	substitute_color default_color_scheme.xpm color_scheme.xpm
	echo "new color scheme : $color_scheme"
esac

cd $image_dir_out
rm -r -f $folders
mkdir -p $folders

case $arg in
c|G|h)
echo "convert images : $folders..."
	if [[ $path_lists == 'file' ]]
	then
		recolor_paths=$RECOLOR_PATHS
		png_recolor_paths=($(make_paths $png_folders))
		svg_recolor_paths=($(make_paths $svg_folders | sed 's/.png/.svg/g'))
	else
	#elif [[ $path_lists == 'dir' ]]
		cd $image_dir_in
		svg_recolor_paths=($(find **/*.svg -type f))
		png_recolor_paths=($(find **/*.png -type f))
		cd -
	fi

	recolor_path $recolor_png $png_recolor_paths
	recolor_path substitute_color $svg_recolor_paths
esac

if [[ $composite == 'TRUE' ]]
then
	if [[ $path_lists == 'file' ]]
	then
	echo "compose images : $png_folders..."
	recolor_paths=$COMPOSITE_PATHS
	composite_paths=($(make_paths $png_folders))
	recolor_paths=$PART1_PATHS
	part1_paths=($(make_paths $png_folders))
	recolor_paths=$PART2_PATHS
	part2_paths=($(make_paths $png_folders))
	else
	#elif [[ $path_lists == 'dir' ]]
	echo "compose images : $image_dir_in..."
	part2_dir=$image_dir_in/stock
	cd $image_dir_in
	part1_paths=($(find **/*.png -type f))
	composite_paths=$image_dir_out
	cd $part2_dir
	part2_paths=($(find **/*.png -type f))
	fi
	cd $image_dir_out
	compose_images $composite_paths
fi
