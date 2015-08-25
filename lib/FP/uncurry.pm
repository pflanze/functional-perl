#
# Copyright (c) 2013-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::uncurry

=head1 SYNOPSIS

 use FP::uncurry;

 my $mult= uncurry sub { my ($x)=@_; sub { my ($y)=@_; $x*$y }};
 &$mult(2,3) # -> 6

 # 'uncurry' is an alias to 'uncurry_1_1'
 my $mult= uncurry_1_1 sub { my ($x)=@_; sub { my ($y)=@_; $x*$y }};
 &$mult(2,3) # -> 6

 my $mult3= uncurry_2_1 sub { my ($x,$y)=@_; sub { my ($z)=@_; $x*$y*$z }};
 &$mult3(2,3,4) # -> 24

=head1 DESCRIPTION

Sometimes it's easier to write code in a curried fashion. Often users
still expect to receive an uncurried ("normal") version of the
function. `uncurry_1_1 $fn` returns a function that expects 2
arguments, passes one to $fn and then the other one to the function
that $fn returns. Other variants behave similarly: the appendix tells
how many arguments each function level expects; the added numbers
determine how many arguments the resulting function expects.

=head1 TODO

Add tail-call optimization to the last call in the chain. Waiting till
Sub::Call::Tail is fixed, or better, we've got a switchable variant.

=head1 SEE ALSO

There are various modules for currying (the inverse of uncurry) on
CPAN.

=cut


package FP::uncurry;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(
	      uncurry
	      uncurry_1_1
	      uncurry_2_1
	      uncurry_2_1
	      uncurry_2_2
	      uncurry_1_1_1
	 );
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

# Macros would be useful here.

sub uncurry_1_1 ($) {
    my ($f)=@_;
    sub {
	@_==2 or die "expecting 2 arguments";
	my ($a,$b)=@_;
	$f->($a)->($b)
    }
}

sub uncurry ($);
*uncurry= *uncurry_1_1;

sub uncurry_2_1 ($) {
    my ($f)=@_;
    sub {
	@_==3 or die "expecting 3 arguments";
	my ($a,$b,$c)=@_;
	$f->($a,$b)->($c)
    }
}

sub uncurry_2_1 ($) {
    my ($f)=@_;
    sub {
	@_==3 or die "expecting 3 arguments";
	my ($a,$b,$c)=@_;
	$f->($a)->($b,$c)
    }
}

sub uncurry_2_2 ($) {
    my ($f)=@_;
    sub {
	@_==4 or die "expecting 4 arguments";
	my ($a,$b,$c,$d)=@_;
	$f->($a,$b)->($c,$d)
    }
}

sub uncurry_1_1_1 ($) {
    my ($f)=@_;
    sub {
	@_==3 or die "expecting 3 arguments";
	my ($a,$b,$c)=@_;
	$f->($a)->($b)->($c)
    }
}

# ...

1
