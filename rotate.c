// rotate hue from color

#include <stdlib.h>
#include <stdio.h>
#include "colorsys.h"


int main(int argc, char* argv[]) {
	struct rgb_color rgb, BC_RGB, Cref_RGB;
	struct hsv_color hsv, BC_HSV, Cref_HSV;
	char hexa[7];
	double hue_angle;
	if ( strcmp(argv[1], "-hue") == 0 ) {
	hue_angle = atof(argv[2]);
	} else {
	BC_RGB = hexa_to_rgb (argv[1]);
	BC_HSV = rgb_to_hsv (BC_RGB);

	Cref_RGB = hexa_to_rgb (argv[2]);
	Cref_HSV = rgb_to_hsv (Cref_RGB);
	hue_angle = Cref_HSV.h - BC_HSV.h;
	}
	if ( argv[3] == NULL ) {
		if (hue_angle < 0 ) {
			hue_angle += 360.0;
		}
		hue_angle = round(hue_angle);
		printf ("%d\n", (int)hue_angle);
	} else {
			FILE *ifp, *ofp;
		
			ifp = fopen( argv[3], "r");
		
			if (ifp == NULL) {
				fprintf(stderr, "Can't open input file %s!\n", argv[3]);
				exit(1);
			}

			while (fscanf(ifp, "%s", hexa) != EOF) {
			rgb = hexa_to_rgb (hexa);
			hsv = rgb_to_hsv(rgb);
			hsv.h = hsv.h + hue_angle;
				if (hsv.h < 0 ) {
					hsv.h += 360.0;
				} else if (hsv.h > 360 ) {
					hsv.h -= 360.0;
				}
			rgb = hsv_to_rgb(hsv);
			rgb.r = round(rgb.r);
			rgb.g = round(rgb.g);
			rgb.b = round(rgb.b);
			rgb_to_hexa (rgb);
			}
		}
	return 0;
}
