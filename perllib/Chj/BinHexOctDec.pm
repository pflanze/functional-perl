package Chj::BinHexOctDec;

# Sat Mar 15 16:38:58 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
#
# $Id$

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
