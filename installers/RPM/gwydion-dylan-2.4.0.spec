#
#Spec file for Gwydion Dylan RPM
#

Summary: Gwydion Dylan development tools
Name: gwydion-dylan
Version: 2.4.0
Release: 2
License: MIT Style
Group: Development/Languages
Source: ftp://ftp.gwydiondylan.org/pub/gd/src/tar/gwydion-dylan-2.4.0.tar.gz
URL: http://www.gwydiondylan.org/
Vendor: Gwydion Dylan Maintainers <gd-hackers@gwydiondylan.org>
Packager: Gwydion Dylan Maintainers <gd-hackers@gwydiondylan.org>
BuildRoot: /tmp/gd-root
Prefix: /usr
AutoReq: 0

%description
Dylan is an advanced, object-oriented, dynamic language which supports the rapid development of programs. When needed, the programmer can later optimize their programs for more efficient execution by supplying type information to the compiler. Dylan is fast, flexible and capable of unusually sophisticated abstractions.

For more infomration, see the Gwydion Dylan maintainers' web page at
<http://www.gwydiondylan.org/>.
%prep
if ! which d2c > /dev/null 2>&1 ; then
   echo "Must have d2c installed to build dylan."
   echo "Please try installing the Gwydion Dylan RPMs"
   exit 1
fi
%setup
%build
if [ ! -f configure ]; then
  ./autogen.sh --prefix=/usr 
else
  ./configure --prefix=/usr 
fi
make
%install
make DESTDIR=$RPM_BUILD_ROOT install
%pre
cat >/tmp/gccheck.c <<EOF
#include <gc.h>
int main(){
 GC_malloc(100);
 return 0;
}
EOF
if ! gcc /tmp/gccheck.c -o /tmp/gccheck -lgc -ldl > /dev/null 2>&1 ;then
 echo "You do not seem have the The Boehm-Demers-Weiser"
 echo "conservative garbage collector installed."
 echo "This library is required to build Dylan programs"
 echo "You can download the sources from:"
 echo "http://www.hpl.hp.com/personal/Hans_Boehm/gc/"
fi
%files
/usr/bin/mindy
/usr/bin/mindycomp
/usr/bin/mindyexec
/usr/bin/d2c
/usr/bin/dybug
/usr/bin/parsergen
/usr/bin/melange
/usr/bin/gen-makefile
/usr/bin/mk-build-tree
/usr/bin/line-count
/usr/bin/make-dylan-app
/usr/bin/make-dylan-lib
/usr/lib/dylan/*
/usr/include/runtime.h
/usr/share/dylan/*

/usr/man/man1/d2c.1.gz
/usr/man/man1/dybug.1.gz
/usr/man/man1/gobject-tool.1.gz
/usr/man/man1/make-dylan-app.1.gz
/usr/man/man1/melange.1.gz
/usr/man/man1/mindy.1.gz
/usr/man/man1/mindycomp.1.gz
/usr/man/man1/mindyexec.1.gz
/usr/man/man1/parsergen.1.gz
/usr/man/man4/platforms.descr.4.gz
/usr/man/man7/dylan.7.gz
/usr/man/man7/gwydion.7.gz