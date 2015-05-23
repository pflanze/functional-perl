#
# Copyright 2014 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::FP::Div

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FP::Div;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(identity inc dec compose compose_scalar);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Chj::TEST;

sub identity ($) {
    $_[0]
}

sub inc ($) {
    $_[0] + 1
}

sub dec ($) {
    $_[0] - 1
}

sub compose {
    my (@fn)= reverse @_;
    sub {
	my (@v)= @_;
	for my $fn (@fn) {
	    @v= &$fn(@v);
	}
	wantarray ? @v : $v[-1]
    }
}

# same as compose, but request scalar context between the calls
sub compose_scalar {
    my (@fn)= reverse @_;
    my $f0= pop @fn;
    my $fx= shift @fn;
    sub {
	my $v= &$fx;
	for my $fn (@fn) {
	    $v= &$fn($v);
	}
	@_=($v); goto $f0
    }
}

TEST { compose (sub { $_[0]+1 }, sub { $_[0]+$_[1] })->(2,3) }
  6;
TEST { compose_scalar  (sub { $_[0]+1 }, sub { $_[0]+$_[1] })->(2,3) }
  6;

TEST { compose (sub { $_[0] / ($_[1]//5) },
		sub { @_ },
		sub { $_[1], $_[0] })
	 ->(2,3) }
  1.5;
TEST { compose_scalar (sub { $_[0] / ($_[1]//5) },
		       sub { @_ },
		       sub { $_[1], $_[0] })
	 ->(2,3) }
  1/5;

1
