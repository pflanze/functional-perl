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
 use FP::List;
 use FP::Div qw(inc);
 equals [1, list(2, 3)], [1, list(1, 2)->map(*inc)]; # -> 1
 equals [1, list(2, 3)], [1, list(1, 2)]; # -> ''
 equals [1, list(2, 3)], [1, list([], 3)]; # -> undef: "not the same type"

=head1 DESCRIPTION

Deep, generic (but class controlled) structure equality comparison.

Non-objects are hard coded in this module. Objects are expected to
have an `FP_Equals_equals` method that is able to take an argument of
the same class as the object to compare (if it doesn't have such an
object, it simply can't be compared using this module).

This does *name based* type comparison: structurally equivalent
objects do not count as equal if they do not have the same class (or
more general, reference name), the `FP_Equals_equals` method is not
even called; the equals function returns undef in this case.

=head1 TODO

- cycle detection

- immutable version -> equals_now equals_forever

- do we need the possibility for "context" dependent (and not by way
  of subclassing and overriding equals_*) equality comparisons?

=head1 SEE ALSO

L<FP::Equal> for a non-class controlled alternative

L<FP::Show>

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
use FP::Lazy;

sub pointer_eq2 ($$) {
    refaddr($_[0]) == refaddr($_[1])
}

sub equals2 ($$) {
    my ($a,$b)=@_;
    if (!defined $a) {
	if (!defined $b) {
	    1
	} else {
	    if (length ref $b) {
		if (is_promise $b) {
		    @_=($a, force ($b)); goto \&equals2;
		} else {
		    undef
		}
	    } else {
		undef
	    }
	}
    } else {
	# $a is defined
	if (!defined $b) {
	    if (length ref $a) {
		if (is_promise $a) {
		    @_=(force($a), $b); goto \&equals2;
		} else {
		    undef
		}
	    } else {
		undef
	    }
	} else {
	    # both are defined
	    if (length (my $ar= ref $a)) {
		if (length (my $br= ref $b)) {
		    pointer_eq2 ($a, $b) or
		      do {
			  if (is_promise $a or is_promise $b) {
			      @_=(force ($a), force ($b)); goto \&equals2;
			  } elsif ($ar eq $br) {
			      if (my $cmp= $$primitive_equals{$ar}) {
				  &$cmp (@_)
			      } else {
				  $a->FP_Equals_equals ($b)
			      }
			  } else {
			      undef
			  }
		      };
		} else {
		    # $b is not a reference ($a is)
		    if (is_promise $a) {
			@_=(force ($a), $b); goto \&equals2;
		    } else {
			undef
		    }
		}
	    } else {
		# $a is not a reference
		if (length ref $b) {
		    if (is_promise $b) {
			@_=($a, force($b)); goto \&equals2;
		    } else {
			undef
		    }
		} else {
		    # $b is not a reference either
		    # make sure it's the same kind of non-reference values:
		    if (ref (\$a) eq ref (\$b)) {
			# XX number comparison could optimize the case where both
			# values don't have string representations, compare using
			# == then.

			# XXX Also, on a slightly independent note, and not just
			# an optimization: in the other case (any of the
			# arguments also has a string representation) compare
			# both as string and as number?

			$a eq $b
		    } else {
			undef
		    }
		}
	    }
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
