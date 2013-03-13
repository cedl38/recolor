all: rotate hexa_to_hsv

hexa_to_hsv: hexa_to_hsv.c	colorsys.h
	gcc -lm -o hexa_to_hsv hexa_to_hsv.c

rotate:	rotate.c	colorsys.h
	gcc -lm -o rotate rotate.c

clean:
	rm -rf *.o

cleanall: clean
	rm -rf rotate hexa_to_hsv
