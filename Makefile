PKG_FILES = 	\
	colorcv	\
	colormap	\
	colorpick	\
	ini.xpm	\
	ini.dat	\
	recolor.sh	\
	rotate	

# install directory
DESTDIR = /usr/local/share
BINDIR = /usr/local/bin

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
	ln -s $(DESTDIR)/recolor/recolor.sh $(BINDIR)/recolor

uninstall:
	rm -rf $(DESTDIR)/recolor
	rm -f $(BINDIR)/recolor
