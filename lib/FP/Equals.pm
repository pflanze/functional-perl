#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Equals - generic equality comparison

=head1 SYNOPSIS

 use FP::Equals;
 equals [1, [2, 3]], [1, [1+1, 3]]; # -> 1
 equals [1, [2, 3]], [1, [1+2, 3]]; # -> ''
 equals [1, [2, 3]], [1, [[], 3]]; # -> undef: "not the same type"

=head1 DESCRIPTION

Deep, generic (but class controlled) structure equality comparison.

Non-objects are hard coded in this module. Objects are expected to
have an `equals` method that is able to take an argument of the same
class as the object to compare (if it doesn't have such an object, it
simply can't be compared using this module).

This does *name based* type comparison: structurally equivalent
objects do not count as equal if they do not have the same class (or
more general, reference name), the equals method is not even called;
the equals function returns undef in this case.

=head1 TODO

- cycle detection

- immutable version -> equals_now equals_forever

- do we need the possibility for "context" dependent (and not by way
  of subclassing and overriding equals_*) equality comparisons?

=head1 SEE ALSO

L<FP::Equal> for a non-class controlled alternative

=cut


package FP::Equals;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(equals);
@EXPORT_OK=qw(equals2);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

# I find it odd that nobody did this before. But I can't find anything
# on CPAN.

our $primitive_equals=
  +{
    ARRAY=> sub {
	my ($a,$b)=@_;
	@$a == @$b and do {
	    my $i=0;
	  LP: {
		$i < @$a ? (equals2 ($$a[$i], $$b[$i]) and do{$i++; redo LP})
		  : 1
	    }
	}
    },
    HASH=> sub {
	my ($a,$b)=@_;
	keys %$a == keys %$b and do {
	    for (keys %$a) {
		my $v; $v= (exists $$b{$_} and equals2 ($$a{$_}, $$b{$_}))
		  or return $v;
	    }
	    1
	}
    },
    REF=> sub { # references to references
	my ($a,$b)=@_;
	equals2($$a, $$b)
    },
    # *references* to globs; direct globs are compared in equals2 directly
    GLOB=> sub {
 	# is it the same glob? If it's different ones, compare all of
 	# their contents? XX if so, then also change the direct
 	# comparison in equals2
	'' # since if they are the same, then pointer comparison
           # already did it
    },
    SCALAR=> sub {
	equals(${$_[0]}, ${$_[1]})
    },

    # compare closures using XS? Existing module?
    #CODE=> sub {
    #}
   };


use Scalar::Util qw(refaddr);

sub pointer_eq2 ($$) {
    refaddr($_[0]) == refaddr($_[1])
}

sub equals2 ($$) {
    if (!defined $_[0]) {
	defined $_[1] ? undef : 1
    } else {
	if (length (my $a= ref $_[0])) {
	    if (length (my $b= ref $_[1])) {
		# First check for pointer equality, or rather
		# equivalence since it can be overloaded. XX Do we
		# want to forgo the overloading (would it need to use
		# XS code?) or should it explicitely be part of the
		# mix? XXX If we want to use it, then why not request
		# classes to consistently overload == instead of
		# providing an `equals` method? But then we're missing
		# a way for *fast* pointer comparison, unless we're
		# really using something else (again, XS code?) for
		# that instead.
		#$_[0] == $_[1]
		&pointer_eq2 (@_) or
		  do {
		      if ($a eq $b) {
			  if (my $cmp= $$primitive_equals{$a}) {
			      &$cmp (@_)
			  } else {
			      $_[0]->equals ($_[1])
			  }
		      } else {
			  undef
		      }
		  }
	    } else {
		undef
	    }
	} else {
	    defined $_[1] ?

	      (length (ref $_[1]) ? undef
	       : (
		  # make sure it's the same kind of non-reference values:
		  ref (\ ($_[0])) eq ref (\ ($_[1])) ?
		  # XX number comparison could optimize the case where both
		  # values don't have string representations, compare using
		  # == then.

		  # XXX Also, on a slightly independent note, and not just
		  # an optimization: in the other case (any of the
		  # arguments also has a string representation) compare
		  # both as string and as number?

		  $_[0] eq $_[1]
		 : undef))

		: undef
	}
    }
}

sub equals {
    if (@_ == 2) {
	goto \&equals2
    } elsif (@_ == 1) {
	1
    } else {
	my $a= shift;
	for (@_) {
	    my $v; $v=equals2 ($a, $_)
	      or return $v;
	}
	1
    }
}


1
