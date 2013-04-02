PKG_FILES = 	\
	colorcv	\
	colormap	\
	ini.xpm	\
	ini.dat	\
	recolor.sh	\
	rotate	

# install directory
DESTDIR = /usr/local/share

all: rotate colorcv

colorcv: colorcv.c	colorsys.h
	gcc -lm -o colorcv colorcv.c

rotate:	rotate.c	colorsys.h
	gcc -lm -o rotate rotate.c

clean:
	rm -rf *.o

cleanall: clean
	rm -rf rotate colorcv

install: all
	mkdir -p $(DESTDIR)/recolor
	cp $(PKG_FILES) $(DESTDIR)/recolor

uninstall:
	rm -r $(DESTDIR)/recolor
