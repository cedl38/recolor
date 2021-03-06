/* Copyright (c) 2013 the authors listed at the following URL, and/or
the authors of referenced articles or incorporated external code:
http://en.literateprograms.org/RGB_to_HSV_color_space_conversion_(C)?action=history&offset=20110802173944

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Retrieved from: http://en.literateprograms.org/RGB_to_HSV_color_space_conversion_(C)?oldid=17206
*/

#include <math.h>

#define MIN3(x,y,z)  ((y) <= (z) ? \
						 ((x) <= (y) ? (x) : (y)) \
					 : \
						 ((x) <= (z) ? (x) : (z)))

#define MAX3(x,y,z)  ((y) >= (z) ? \
						 ((x) >= (y) ? (x) : (y)) \
					 : \
						 ((x) >= (z) ? (x) : (z)))

struct rgb_color {
	double r, g, b;	/* color values between 0 and 255 */
};

struct hsv_color {
	double h;		/* Hue degree between 0.0 and 360.0 */
	double s;		/* Saturation between 0.0 (gray) and 100.0 */
	double v;		/* Value between 0.0 and 100.0 */
};

struct hsl_color {
	double h;		/* Hue degree between 0.0 and 360.0 */
	double s;		/* Saturation between 0.0 (gray) and 100.0 */
	double l;		/* Luminance between 0.0 and 100.0 */
};

struct hsv_color rgb_to_hsv(struct rgb_color rgb) {
	//Convert RGB color space to HSV color space
	//@param r: Red
	//@param g: Green
	//@param b: Blue
	//return hsv

	struct hsv_color hsv;
	double rgb_min, rgb_max;
	rgb_min = MIN3(rgb.r, rgb.g, rgb.b);
	rgb_max = MAX3(rgb.r, rgb.g, rgb.b);
	hsv.v = rgb_max * 20.0/51.0;
	if (rgb_min == rgb_max) {
		hsv.h = hsv.s = 0;
		return hsv;
	}
	/* Saturation */
	hsv.s = 100 * (rgb_max - rgb_min) / rgb_max;

	/* Normalize saturation to 1 */
	double rc = (rgb.r - rgb_min)/(rgb_max - rgb_min);
	double gc = (rgb.g - rgb_min)/(rgb_max - rgb_min);
	double bc = (rgb.b - rgb_min)/(rgb_max - rgb_min);

	/* Compute hue */
	if (rgb_max == rgb.r) {
		hsv.h = 60.0*(gc - bc);
		if (hsv.h < 0.0) {
			hsv.h += 360.0;
		}
	} else if (rgb_max == rgb.g) {
		hsv.h = 120.0 + 60.0*(bc - rc);
	} else /* rgb_max == rgb.b */ {
		hsv.h = 240.0 + 60.0*(rc - gc);
	}
	return hsv;
}

struct rgb_color hsv_to_rgb(struct hsv_color hsv) {
	//Convert HSV color space to RGB color space
	//@param h: 0 < Hue < 360
	//@param s: 0 < Saturation < 100
	//@param v: 0 < Value < 100
	//return rgb

	struct rgb_color rgb;
	int region;
	double f, p, q, t;

	if( hsv.s == 0 ) {
		// achromatic (grey)
		rgb.r = rgb.g = rgb.b = hsv.v;
		return rgb;
	}

	hsv.h /= 60.0;			// sector 0 to 5
	hsv.s /= 100.0;			// normalize saturation to 1
	hsv.v  = hsv.v * 51.0/20.0;	// scale value to 255
	region = (int)(hsv.h) % 6;	// assume hue > 0
	f = hsv.h - region;			// factorial part of h
	p = hsv.v * ( 1 - hsv.s );
	q = hsv.v * ( 1 - hsv.s * f );
	t = hsv.v * ( 1 - hsv.s * ( 1 - f ) );

	switch (region) {
		case 0:
			rgb.r = hsv.v;
			rgb.g = t;
			rgb.b = p;
			break;
		case 1:
			rgb.r = q;
			rgb.g = hsv.v;
			rgb.b = p;
			break;
		case 2:
			rgb.r = p;
			rgb.g = hsv.v;
			rgb.b = t;
			break;
		case 3:
			rgb.r = p;
			rgb.g = q;
			rgb.b = hsv.v;
			break;
		case 4:
			rgb.r = t;
			rgb.g = p;
			rgb.b = hsv.v;
			break;
		default:		// case 5:
			rgb.r = hsv.v;
			rgb.g = p;
			rgb.b = q;
			break;
	}
	return rgb;
}


struct hsl_color rgb_to_hsl(struct rgb_color rgb) {
	//Convert RGB color space to HSL color space
	//@param r: Red
	//@param g: Green
	//@param b: Blue
	//return hsl

	struct hsl_color hsl;
	double rgb_min, rgb_max;
	rgb_min = MIN3(rgb.r, rgb.g, rgb.b);
	rgb_max = MAX3(rgb.r, rgb.g, rgb.b);
	hsl.l = (rgb_min + rgb_max)/5.1; // (100/255/2)
	if (rgb_min == rgb_max) {
		hsl.h = hsl.s = 0;
		return hsl;
	}
	/* Saturation */
	if (hsl.l <= 50.0) {
		hsl.s = (rgb_max - rgb_min) / (rgb_max + rgb_min) * 100.0;
	} else {
		hsl.s = (rgb_max - rgb_min) / (510.0 - rgb_max - rgb_min) * 100.0;
	}
	/* Normalize saturation to 1 */
	double rc = (rgb.r - rgb_min)/(rgb_max - rgb_min);
	double gc = (rgb.g - rgb_min)/(rgb_max - rgb_min);
	double bc = (rgb.b - rgb_min)/(rgb_max - rgb_min);

	/* Compute hue */
	if (rgb_max == rgb.r) {
		hsl.h = 60.0 * (gc - bc);
		if (hsl.h < 0.0) {
			hsl.h += 360.0;
		}
	} else if (rgb_max == rgb.g) {
		hsl.h = 120.0 + 60.0 * (bc - rc);
	} else /* rgb_max == rgb.b */ {
		hsl.h = 240.0 + 60.0 * (rc - gc);
	}
	return hsl;
}

double _v (double m1, double m2, double hue) {
	hue = hue - floor(hue);
	if (hue < (1.0/6.0)) {
		return m1 + (m2 - m1) * hue * 6.0;
	}
	if (hue < 0.5) {
		return m2;
	}
	if (hue < (2.0/3.0)) {
		return m1 + (m2 - m1) * (4.0 - hue * 6.0);
	}
	return m1;
}

struct rgb_color hsl_to_rgb(struct hsl_color hsl) {
	//Convert HSL color space to RGB color space
	//@param h: 0 < Hue < 360
	//@param s: 0 < Saturation < 100
	//@param v: 0 < Luminance < 100
	//return rgb

	struct rgb_color rgb;
	double m1, m2;

	if( hsl.s == 0 ) {
		// achromatic (grey)
		rgb.r = rgb.g = rgb.b = hsl.l;
		return rgb;
	}
	hsl.h /= 360.0;			// sector 0 to 1
	hsl.l /= 100.0;	// normalize luminance to 1
	hsl.s /= 100.0;			// normalize saturation to 1
	if (hsl.l <= 0.5) {
		m2 = hsl.l * (1.0 + hsl.s);
	} else {
		m2 = hsl.l + hsl.s - (hsl.l * hsl.s);
	}
	m1 = 2.0 * hsl.l - m2;
	rgb.r = _v(m1, m2, hsl.h+1.0/3.0) * 255.0;
	rgb.g = _v(m1, m2, hsl.h) * 255.0;
	rgb.b = _v(m1, m2, hsl.h-1.0/3.0) * 255.0;
	return rgb;
}

struct rgb_color hexa_to_rgb(char color_hexa[]) {
	short i = 0;
	char s[3]="00";
	short x[3];
	unsigned long a = 0;
	for (i = 0; i < 3; i++) {
		s[0] = color_hexa[a];
		s[1] = color_hexa[a+1];
		a = a + 2;
		x[i] = strtoul(s, 0, 16);
	}
	struct rgb_color rgb;
	rgb.r = x[0];
	rgb.g = x[1];
	rgb.b = x[2];
	return rgb;
}

char rgb_to_hexa (struct rgb_color rgb) {
	char color_hexa[7];
	printf ("%02x%02x%02x\n", (int)rgb.r, (int)rgb.g, (int)rgb.b);
}
