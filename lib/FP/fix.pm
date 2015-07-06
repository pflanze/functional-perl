#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

FP::fix -- recurse with the fix point combinator

=head1 SYNOPSIS

 use FP::fix;

 sub foo {
     my ($z)= @_;
     my $local= fix sub {
         my ($local, $x, $y)=@_;
         $x > 0 ? &$local ($x-1, $x*$y) : $y
     };
     &$local ($z, 0)
 }


=head1 DESCRIPTION

fix takes a function and returns another function that when called
calls the original function and gives it the fix'ed function as first
argument and then the original arguments.

This allows to write self-recursive local functions without having to
deal with the problem of reference cycles that self-referencing
closures would run into.

The example from the synopsis is equivalent to:

 use Scalar::Util 'weaken';

 sub foo {
     my ($z)= @_;
     my $local; $local= sub {
         my ($x, $y)=@_;
         $x > 0 ? &$local ($x-1, $x*$y) : $y
     };
     my $_local= $local; weaken $local;
     &$local ($z, 0)
 }


=cut


package FP::fix;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(fix fixn);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

# Alternative implementations:

# Y combinator
*Y= do {
	my $fix0= sub {
	    my ($fix0, $f)=@_;
	    sub {
		@_=(&$fix0 ($fix0, $f), @_); goto $f;
	    }
	};
	sub ($) {
	    my ($f)=@_;
	    &$fix0 ($fix0, $f)
	}
    };

# self-referencing through package variable
*rec=
    sub ($) {
	my ($f)=@_;
	sub {
	    #@_=(fix ($f), @_); goto $f;
	    unshift @_, fix ($f); goto $f;
	}
    };

# locally self-referencing

use Scalar::Util 'weaken';

*weakcycle=
    sub ($) {
	my ($f)=@_;
	my $f2; $f2= sub {
	    unshift @_, $f2; goto $f
	};
	my $f2_=$f2; weaken $f2; $f2_
    };



sub fix ($);

*fix= *weakcycle;


# n-ary version:

sub fixn {
    my (@f)=@_;
    my @ff;
    for (my $i=0; $i<@f; $i++) {
	my $f= $f[$i];
	$ff[$i]= sub {
	    unshift @_, @ff; goto $f;
	}
    }
    my @ff_= @ff;
    # weaken $_ for @ff;
    # ^ XXX: releases too early, same issue as
    #   mentioned in `intro/more_tailcalls`
    wantarray ? @ff_ : do {
	@ff==1 or die "fixn: got multiple arguments, but scalar context";
	$ff_[0]
    }
}


1
