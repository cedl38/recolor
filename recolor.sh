#!/bin/zsh
zmodload zsh/mathfunc

# dependencies : imagemagick >= v6.5.3, libpng, librsvg, libxml
set -e

# parameters
#############
CRef='000000'
modulate_hue=100
modulate_brightness=100
modulate_saturation=100
png_subdirs=(16x16 22x22 32x32)
svg_subdirs=(scalable)
part2_subdir=
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
}

# steps :
##########


# (b-a)/(p1-a) == (y-x) (p2-x)
# x = (p1*x - b*x + b*p2 - a*p2)/(p1 - a)
alpha() {
if [[ $3 > $2 ]]
then
echo $(( ($1*100 - $3*100 + $3*200 - $2*200) / ($1 - $2) ))
else
echo $((100 * $3 / $2))
fi
}

hexacv() {
	for i
	do
		if [[ "${i:0:1}" == '#' ]]
		then
			echo "${i:1:6}"
		else
			# convert color name to hexa
			echo $(grep -P "$i\t" colormap | cut -f3 | cut -d'#' -f2)
		fi
	done
}

alpha() {
if [[ $3 > $2 ]]
then
echo $(((200*$3-200*$2+100*$1-100*$3)/($1-$2)))
else
echo $((100 * $3 / $2))
fi
}

color() {
convert $1 -fill "#$CRef" -tint $tint $1
}

discolor() {
convert $1 -type GrayScaleMatte $1
}

recolor() {
convert $1 -modulate $modulate_brightness,$modulate_saturation,$modulate_hue $1
}

substitute_color() {
image=$1
j=1;
set $color_scheme_ini
	for i
	do
	sed -i "s/\#$i/\#$color_scheme[j]/g" $image
	(( j++ ))
	done
}

recolor_xpm() {
for i
do
	sed "s/#0*/#$i/" ini.xpm > color.xpm
	$recolor_png color.xpm
	color=($(grep -o 'c [#0-9a-ZA-Z]*"' $MAIN_DIR/color.xpm | grep -v 'None' | cut -d' ' -f2 | cut -d\" -f1))
	if [[ "${color:0:1}" == '#' ]]
	then
		# workaround : convert color hexa 12 to 6 characters
		echo "${color:1:2}${color:5:2}${color:9:2}" | tr '[A-Z]' '[a-z]'
	else
		# convert color name to hexa
		echo $(grep -P "$color\t" colormap | cut -f3 | cut -d'#' -f2)
	fi
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
composite $part2_dir/$part2_paths[i] $part1_paths[i] $composite_path
(( i++ ))
done
}

modulate_hue() {
if [[ $DSTHUE > $SRCHUE ]]
then
modulate_hue=$(( ($DSTHUE - $SRCHUE) * 100/180 + 100 ))
else
modulate_hue=$(( ($DSTHUE - $SRCHUE) * 100/180 + 300 ))
fi
}

# options
##########

color_value() {
case $1 in;
Br)				CRef='DD9A3A'	;;
\#*)			CRef="${1:1:6}" 	;;
[a-z][a-z1-9]*)	CRef=$(grep -P "$1\t" colormap | cut -f3 | cut -d'#' -f2) ;;
*) echo "Invalid color"; exit 1	;;
esac
}

show_help() {
echo "
usage : [OPTIONS] [ARG] <dir-in> <dir-out>
ARGUMENTS :
	-b <brightness> : modulate brightness (0 to 200)
	-c <color> : by name or hexadecimal <Br>=Brown
	-G <brightness> : convert image to grayscale and modulate brightness
	-G : convert image to grayscale
	-h <hue-angle> / <src-hue,dst-hue> : modulate hue angle or hue source, destination.
	-s <saturation> : modulate saturation (0 to 200)
OPTIONS :
	-B : modulate brightness from -c arg.
	-f <-c> <tint> : fill color tint (0 to 100)
	-F : fill color tint=100
	-H : modulate hue from -c arg.
	-O : compose icons with composite function
	-p <paths-lists> : file contain list of pathname parameters
	-S : modulate saturation from -c arg.
"
}

# default recolor function for png files
recolor_png=recolor
data_file='data_ini'
# default data source
source data_ini
composite='FALSE'
H='FALSE'; S='FALSE'; B='FALSE'

while getopts b:Bc:f:Fg:Gh:HOp:s:S opt
do
	case $opt in
	b)	arg=m; modulate_brightness=$OPTARG ;;
	B)	B='TRUE' ;;
	c)	arg=c; color_value $OPTARG ;;
	f)	recolor_png=color; tint=$OPTARG	;;
	F)	recolor_png=color; tint=100	;;
	g)	arg=g; modulate_brightness=$OPTARG; recolor_png=discolor ;;
	G)	arg=G; recolor_png=discolor	;;
	h)	arg=m
		HUES=$(expr $OPTARG : '\([,0-9]*\)')
		if expr $OPTARG : '\(.*,.*\)' > /dev/null
		then
			SRCHUE=$(echo $HUES | cut -d, -f 1)
			DSTHUE=$(echo $HUES | cut -d, -f 2)
			modulate_hue
		else
			modulate_hue=$HUES
		fi
		;;
	H)	H='TRUE' ;;
	O)	composite='TRUE' ;;
	p)	source $OPTARG; data_file="$OPTARG" ;;
	s)	arg=m; modulate_saturation=$OPTARG ;;
	S)	S='TRUE' ;;
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

if [[ $RECOLOR_PATHS == '' ]]
then
	svg_recolor_paths=($(find **/*.svg -type f))
	png_recolor_paths=($(find **/*.png -type f))
else
	recolor_paths=$RECOLOR_PATHS
	png_recolor_paths=($(make_paths $png_subdirs))
	svg_recolor_paths=($(make_paths $svg_subdirs | sed 's/.png/.svg/g'))
fi

if [[ $2 == '' ]]
then
	if [[ $1 == '' ]]
	then
	IMAGE_DIR_OUT=$MAIN_DIR/cache
	else
	IMAGE_DIR_OUT=$(realpath $1)
	fi
	# recursive functionality
	if [[ $data_file == 'data_ini' ]] && [[ -f $IMAGE_DIR_OUT/out.dat ]]
	then
		# load generated data file if exist
		data_file="$IMAGE_DIR_OUT/out.dat"
		source $data_file
		COLOR_SCHEME_INI=($COLOR_SCHEME)
	fi
else
	# (re)load IMAGE_DIR_OUT
	IMAGE_DIR_IN=$(realpath $1)
	IMAGE_DIR_OUT=$(realpath $2)
	set $png_recolor_paths $svg_recolor_paths
	for recolor_path
	do
		rm -r -f $IMAGE_DIR_OUT/$recolor_path
		mkdir -p $IMAGE_DIR_OUT/$(dirname $recolor_path)
		cp -r -f $IMAGE_DIR_IN/$recolor_path $IMAGE_DIR_OUT/$recolor_path
	done
fi

case $arg in
c|g|G|m)

	color_scheme_ini=($(hexacv $COLOR_SCHEME_INI))
	echo "default color scheme : $COLOR_SCHEME_INI"
	set $color_scheme_ini
	top_color=$1; buttom_color=$2; border_color=$3
	if [[ $arg == 'c' ]]
	then
		if [[ $H == 'FALSE' ]] && [[ $S == 'FALSE' ]] && [[ $B == 'FALSE' ]]
		then
			H='TRUE'; S='TRUE'; B='TRUE'
		fi
		BC_hsl=($(./colorcv $buttom_color -hsl))
		CRef_hsl=($(./colorcv $CRef -hsl))
		SRCHUE=$BC_hsl[1]
		DSTHUE=$CRef_hsl[1]
		if [[ $H == 'TRUE' ]]
		then
			modulate_hue
		fi
		if [[ $S == 'TRUE' ]]
		then
			modulate_saturation=$(alpha 100 $BC_hsl[2] $CRef_hsl[2])
		fi
		if [[ $B == 'TRUE' ]]
		then
			modulate_brightness=$(alpha 100 $BC_hsl[3] $CRef_hsl[3])
		fi
	fi

	cd $IMAGE_DIR_OUT
	echo "convert images : $SUBDIRS..."
	recolor_path $recolor_png $png_recolor_paths
	case $arg in
	g)	recolor_path recolor $png_recolor_paths
	esac

	cd $MAIN_DIR
	color_scheme=($(recolor_xpm $color_scheme_ini))

	case $arg in
	g)	$recolor_png=recolor
		color_scheme=($(recolor_xpm $color_scheme))
		recolor_path recolor $png_recolor_paths
	esac

	i=1; set $color_scheme
	for color; do COLOR_SCHEME[i]="'#$color'"; (( i++ )); done
	echo "new color scheme : $COLOR_SCHEME"
	sed "s/COLOR_SCHEME_INI=(.*)/COLOR_SCHEME=($COLOR_SCHEME)/" $data_file > $IMAGE_DIR_OUT/out.dat
	cd -

	recolor_path substitute_color $svg_recolor_paths
esac

if [[ $composite == 'TRUE' ]]
then
	cd $IMAGE_DIR_OUT
	part2_dir=stock
	if [[ $COMPOSITE_PATHS == '' ]]
	then
	echo "compose images : $IMAGE_DIR_OUT..."
	part1_paths=($(find **/*.png -type f))
	composite_paths=$IMAGE_DIR_OUT
	cd $part2_dir
	part2_paths=($(find **/*.png -type f))
	cd -
	else
	echo "compose images : $png_subdirs..."
	recolor_paths=$COMPOSITE_PATHS
	composite_paths=($(make_paths $png_subdirs))
	recolor_paths=$PART1_PATHS
	part1_paths=($(make_paths $png_subdirs))
	recolor_paths=$PART2_PATHS
	cd $part2_dir
	part2_paths=($(make_paths $png_subdirs))
	cd -
	fi
	compose_images $composite_paths
fi
