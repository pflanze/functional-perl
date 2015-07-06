#
# Copyright (c) 2003-2014 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License. See the file COPYING.md that came bundled with this
# file.
#

=head1 NAME

Chj::BinHexOctDec 

=head1 SYNOPSIS

 my $num= Chj::BinHexOctDec->bin("1001010010");
 print $num->dec;

=head1 DESCRIPTION

Conversions between number bases.

The methods are overloaded both as class methods (to convert *from*
that base) and object method (*to* that base).

Note: does not die on invalid input. (Should this be considered a
bug?)

=head1 METHODS

 dec
 bin
 hex
 oct

=cut


package Chj::BinHexOctDec;

use strict;

sub bin {
    my $this=shift;
    if (ref $this) {
	sprintf('%b',$$this)
    } else {
	my $data=oct('0b'.shift);
	bless \$data,$this
    }
}

sub dec {
    my $this=shift;
    if (ref $this) {
	$$this
    } else {
	my $data=shift;
	bless \$data,$this
    }
}

sub oct {
    my $this=shift;
    if (ref $this) {
	sprintf('%o',$$this)
    } else {
	my $data=oct('0'.shift);
	bless \$data,$this
    }
}

sub hex {
    my $this=shift;
    if (ref $this) {
	sprintf('%x',$$this)
    } else {
	my $data= hex(shift); # oct('0x'.shift); should work as well
	bless \$data,$this
    }
}


1
