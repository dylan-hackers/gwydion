mogrifier.lib.du: mogrifier.lid mogrifier.dylan mogrifier-exports.dylan
	d2c mogrifier.lid

clean:
	-rm -f *.o *.s *.a *.c *.mak *~ mogrifier.lib.du
	-rm -rf .libs

install: mogrifier.lib.du 
	libtool /usr/bin/install -c libmogrifier.a mogrifier.lib.du `d2c --dylan-user-location`
