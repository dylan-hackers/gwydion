#!/usr/bin/perl

# This is a temporary workaround for the lack of a working 
# "make clean" for GD.  TAKE CARE...this will remove any
# work you've done in the current directory that hasn't been
# svn added yet!

open(ST, "svn st --no-ignore |");
while(<ST>) {
    if(/^[I?].{7}(.*)$/) {
	print "$1\n";
	if(-d $1) {
	    system "rm -rf '$1'";
	}
	else {
	    unlink $1;
	}
    }
}
