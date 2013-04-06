#!/bin/zsh
zmodload zsh/mathfunc

# dependencies : imagemagick >= v6.5.3, libpng, librsvg, libxml
set -e

make_paths() {
paths=''
for folder
do
paths_folder=($(echo -e $(echo $recolor_paths|sed 's/ /\\n/g')| sed "s/^/$folder\//g"))
paths=($paths $paths_folder)
done
echo $paths
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
			echo $(grep -P "$i\t" $MAIN_DIR/colormap | cut -f3 | cut -d'#' -f2)
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

recolor() {
convert $1 $imarg $1
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
	sed "s/#0*/#$i/" ini.xpm > /tmp/recolor_color.xpm
	recolor /tmp/recolor_color.xpm
	color=($(grep -o 'c [#0-9a-ZA-Z]*"' /tmp/recolor_color.xpm | grep -v 'None' | cut -d' ' -f2 | cut -d\" -f1))
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

modulate_arg() {
	if [[ $H == 'FALSE' ]] && [[ $S == 'FALSE' ]] && [[ $L == 'FALSE' ]]
	then
		H='TRUE'; S='TRUE'; L='TRUE'
	fi
		CRefIn_hsl=($(./colorcv $1 -hsl))
		CRefOut_hsl=($(./colorcv $2 -hsl))
		SRCHUE=$CRefIn_hsl[1]
		DSTHUE=$CRefOut_hsl[1]

	if [[ $H == 'TRUE' ]]
	then
		modulate_hue
	else
		modulate_hue=100
	fi
	if [[ $S == 'TRUE' ]]
	then
		modulate_saturation=$(alpha 100 $CRefIn_hsl[2] $CRefOut_hsl[2])
	else
		modulate_saturation=100
	fi
	if [[ $L == 'TRUE' ]]
	then
		modulate_brightness=$(alpha 100 $CRefIn_hsl[3] $CRefOut_hsl[3])
	else
		modulate_brightness=100
	fi
}

# options
##########

color_value() {
case $1 in;
Br)			 	echo 'DD9A3A'	;;
\#*)			echo "${1:1:6}"	;;
[a-z][a-z1-9]*)	echo $(grep -P "$1\t" colormap | cut -f3 | cut -d'#' -f2) ;;
*)				echo "Invalid color"; exit 1 ;;
esac
}

show_help() {
echo "
usage : <dir-in> [ImageMagick ARG1] [ARG] [OPTIONS] [ImageMagick ARG2] <dir-out>
ImageMagick ARGUMENTS 1|2 : Convert argument from ImageMagick
ARGUMENTS :
	-m <color-ref-in>,<color-ref-out> | <color-ref-out> : move color from initial,destination (name or hexadecimal value). <Br>=Brown
OPTIONS :
	-C : generate a color scheme from svg files
	-L : modulate luminance from -m arg.
	-H : modulate hue from -m arg.
	-O : compose icons with composite function
	-p <paths-lists> : file contain list of pathname parameters
	-S : modulate saturation from -m arg.
	"
}


# default parameters
#####################
MAIN_DIR=$(dirname $(realpath $0))
# default data source
data_file='ini.dat'
source $MAIN_DIR/ini.dat
composite='FALSE'; C='FALSE'; H='FALSE'; S='FALSE'; L='FALSE'
arg=''; imarg1=''; imarg2=''

case $1 in
-*)	IMAGE_DIR_IN='' ;;
*)	IMAGE_DIR_IN=$(realpath $1) ; shift ;;
esac

# parse options
until [[ $# = 0 ]]
do
	case $# in
	1) IMAGE_DIR_OUT=$(realpath $1) ;;
	*)
		case $1 in
		-C)	C='TRUE' ;;
		-m)	arg=m
			CRefs=$(expr $2 : '\([,#0-9]*\)')
			if expr $2 : '\(.*,.*\)' > /dev/null
			then
				CRefIn=($(color_value $(echo $CRefs | cut -d, -f 1)))
				CRefOut=($(color_value $(echo $CRefs | cut -d, -f 2)))
			else
				CRefOut=($(color_value $CRefs))
			fi
			shift
			;;
		-M) arg=M ;;
		-H)	H='TRUE' ;;
		-L)	L='TRUE' ;;
		-O)	composite='TRUE' ;;
		-p)	source $2 ; data_file="$(realpath $2)"
			if [[ $CRefIn == '' ]]
			then CRefIn=($(color_value $CREF_IN)); fi
			if [[ $CRefOut == '' ]]
			then CRefOut=($(color_value $CREF_OUT)); fi
			shift ;;
		-S)	S='TRUE' ;;
		\?) show_help; exit 1 ;;
		*) if test -z "$arg"; then imarg1=($imarg1 $1); else imarg2=($imarg2 $1); fi 
			;;
		esac
	esac
shift
done

cd $MAIN_DIR

reload='FALSE'
if [[ $IMAGE_DIR_IN == '' ]]
then
	# recursive functionality
	if [[ $data_file == 'ini.dat' ]] && [[ -f $IMAGE_DIR_OUT/out.dat ]]
	then
		# load generated data file if exist
		data_file="$IMAGE_DIR_OUT/out.dat"
		source $data_file
		COLOR_SCHEME_INI=($COLOR_SCHEME)
		if [[ $CRefIn == '' ]]
		then CRefIn=($(color_value $CREF_IN)); fi
		if [[ $CRefOut == '' ]]
		then CRefOut=($(color_value $CREF_OUT)); fi
	fi
else
	# (re)load IMAGE_DIR_OUT
	reload='TRUE'
fi

# make paths
mkdir -p $IMAGE_DIR_OUT
SUBDIRS=($PNG_SUBDIRS $SVG_SUBDIRS)
if [[ $RECOLOR_PATHS == '' ]]
then
	cd $IMAGE_DIR_IN
	svg_recolor_paths=($(find . -name "*.svg" -type f | cut -d'/' -f2))
	png_recolor_paths=($(find . -name "*.png" -type f))
	cd -

else
	cd $IMAGE_DIR_OUT
	recolor_paths=$RECOLOR_PATHS
	png_recolor_paths=($(make_paths $PNG_SUBDIRS))
	svg_recolor_paths=($(make_paths $SVG_SUBDIRS | sed 's/.png/.svg/g'))
	cd -
fi

# reload path
case $reload in
'TRUE')
	set $png_recolor_paths $svg_recolor_paths
	for recolor_path
	do
		rm -r -f $IMAGE_DIR_OUT/$recolor_path
		mkdir -p $IMAGE_DIR_OUT/$(dirname $recolor_path)
			if [[ -f $IMAGE_DIR_IN/$recolor_path ]]
			then
			cp -r -f $IMAGE_DIR_IN/$recolor_path $IMAGE_DIR_OUT/$recolor_path
			fi
	done
esac

# modulate arguments
modulate_arg=''
case $arg in
m|M)	modulate_arg $CRefIn $CRefOut
	modulate_arg=(-modulate $modulate_brightness,$modulate_saturation,$modulate_hue)
esac

imarg=($imarg1 $modulate_arg $imarg2)

if [[ $imarg != '' ]]
then
# recolor png
	cd $IMAGE_DIR_OUT
	echo "convert images : $SUBDIRS..."
	recolor_path recolor $png_recolor_paths

echo $imarg1 $IMAGE_DIR_IN

# recolor svg
	if [[ $C == 'TRUE' ]]
	then
		COLOR_SCHEME_INI=($($MAIN_DIR/colorpick $svg_recolor_paths))
	fi
	echo "default color scheme : $COLOR_SCHEME_INI"
	color_scheme_ini=($(hexacv $COLOR_SCHEME_INI))

	cd $MAIN_DIR
	color_scheme=($(recolor_xpm $color_scheme_ini))

	i=1; set $color_scheme
	for color; do COLOR_SCHEME[i]="'#$color'"; (( i++ )); done
	echo "new color scheme : $COLOR_SCHEME"
	sed "s/COLOR_SCHEME_INI=(.*)/COLOR_SCHEME=($COLOR_SCHEME)/" $data_file > /tmp/recolor_tmp.dat
	mv /tmp/recolor_tmp.dat $IMAGE_DIR_OUT/out.dat
	sed -i "s/CREF_IN='.*'/CREF_IN=\'\#$CRefOut\'/" $IMAGE_DIR_OUT/out.dat
	cd -

	recolor_path substitute_color $svg_recolor_paths
fi

# compose images
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
	echo "compose images : $PNG_SUBDIRS..."
	recolor_paths=$COMPOSITE_PATHS
	composite_paths=($(make_paths $PNG_SUBDIRS))
	recolor_paths=$PART1_PATHS
	part1_paths=($(make_paths $PNG_SUBDIRS))
	recolor_paths=$PART2_PATHS
	cd $part2_dir
	part2_paths=($(make_paths $PNG_SUBDIRS))
	cd -
	fi
	compose_images $composite_paths
fi
