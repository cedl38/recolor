// rotate hue from color

#include <stdlib.h>
#include <stdio.h>
#include "colorsys.h"

// (b-a)/(p1-a) == (y-x) (p2-x)
double alpha(double x, double a, double b, double p1,  double p2) {
	if (b > a) {
		x = (p1*x - b*x + b*p2 - a*p2)/(p1 - a);
	} else /* else if b < a*/ {
		x = x * b / a;
	}
	return x;
}

int main(int argc, char* argv[]) {
	struct rgb_color rgb, BC_RGB, Cref_RGB;
	struct hsv_color hsv, BC_HSV, Cref_HSV;
	char hexa[7];
	double hue_angle;
	if ( strcmp(argv[1], "-h") == 0 ) {
		hue_angle = atof(argv[2]);
	} else {
		BC_HSV = rgb_to_hsv (hexa_to_rgb (argv[1]));
		Cref_HSV = rgb_to_hsv (hexa_to_rgb (argv[2]));
		hue_angle = Cref_HSV.h - BC_HSV.h;
		if ( strcmp(argv[3], "-h") != 0 ) {
			hsv.s = alpha(hsv.s, BC_HSV.s, Cref_HSV.s, 100.0, 100.0);
			hsv.v = alpha(hsv.v, BC_HSV.v, Cref_HSV.v, 100.0, 100.0);
		}
	}
	if ( strcmp(argv[3], "-h") == 0 ) {
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
