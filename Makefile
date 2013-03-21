all: rotate colorcv

colorcv: colorcv.c	colorsys.h
	gcc -lm -o colorcv colorcv.c

rotate:	rotate.c	colorsys.h
	gcc -lm -o rotate rotate.c

clean:
	rm -rf *.o

cleanall: clean
	rm -rf rotate colorcv
