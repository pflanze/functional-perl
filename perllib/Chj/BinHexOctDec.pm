#
# Copyright 2003-2014 by Christian Jaeger, ch at christianjaeger . ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::BinHexOctDec 

=head1 SYNOPSIS

 my $num= Chj::BinHexOctDec->bin("1001010010");
 print $num->dec;

=head1 DESCRIPTION

Data systems zeugs konversi

Same methods are convertig *from* the named format when used as constuctors,
and the *to* the format when used on an object.

Note: does NOT croak on invalid input but insteda just soweit wie geht

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


1;
