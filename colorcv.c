// colorcv

#include <stdlib.h>
#include <stdio.h>
#include "colorsys.h"

int main(int argc, char* argv[]) {
	if ( strcmp(argv[1], "-hsl") == 0 ) {
		if ( strcmp(argv[5], "-rgb") == 0 ) {
			struct rgb_color rgb;
			struct hsl_color hsl;
			hsl.h=atof(argv[2]);
			hsl.s=atof(argv[3]);
			hsl.l=atof(argv[4]);
			rgb = hsl_to_rgb(hsl);
			rgb.r = round(rgb.r);
			rgb.g = round(rgb.g);
			rgb.b = round(rgb.b);
			printf("%d %d %d\n", (int)rgb.r, (int)rgb.g, (int)rgb.b);
		}
	} else {
		if ( strcmp(argv[2], "-rgb") == 0 ) {
		struct rgb_color rgb;
		rgb = hexa_to_rgb (argv[1]);
		rgb.r = round(rgb.r);
		rgb.g = round(rgb.g);
		rgb.b = round(rgb.b);
		printf("%d %d %d\n", (int)rgb.r, (int)rgb.g, (int)rgb.b);
		} else if ( strcmp(argv[2], "-hsv") == 0 ) {
		struct hsv_color hsv;
		hsv = rgb_to_hsv(hexa_to_rgb (argv[1]));
		hsv.h = round(hsv.h);
		hsv.s = round(hsv.s);
		hsv.v = round(hsv.v);
		printf("%d %d %d\n", (int)hsv.h, (int)hsv.s, (int)hsv.v);
		} else if ( strcmp(argv[2], "-hsl") == 0 ) {
		struct hsl_color hsl;
		hsl = rgb_to_hsl(hexa_to_rgb (argv[1]));
		hsl.h = round(hsl.h);
		hsl.s = round(hsl.s);
		hsl.l = round(hsl.l);
		printf("%d %d %d\n", (int)hsl.h, (int)hsl.s, (int)hsl.l);
		}
	}
	return 0;
}
