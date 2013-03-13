// hexa_to_hsv

#include <stdlib.h>
#include <stdio.h>
#include "colorsys.h"


int main(int argc, char* argv[]) {
	struct hsv_color hsv;
	char hexa[7];
	hsv = rgb_to_hsv(hexa_to_rgb (hexa));
	hsv.h = round(hsv.h);
	hsv.s = round(hsv.s);
	hsv.v = round(hsv.v);
	printf("%d %d %d\n", hsv.h, hsv.s, hsv.v);
	return 0;
}
