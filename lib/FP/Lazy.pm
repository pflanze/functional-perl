#
# Copyright 2013-2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

FP::Lazy

=head1 SYNOPSIS

 use FP::Lazy;

 my $a = lazy { 1 / 0 };
 print force $a # -> Illegal division by zero

 my $b = lazy { warn "evaluation happening"; 1 / 2 };
 print is_promise $b ? "promise" : "non-promise", "\n"; # -> "promise"
 print force ($b), "\n"; # shows the warning, and "0.5"
 # $b is still a promise at this poing (although an evaluated one):
 print is_promise $b ? "promise" : "non-promise", "\n"; # -> "promise"

 # The following stores result of `force $b` back into $b
 FORCE $b; # does not show the warning anymore as evaluation happened already
 print is_promise $b ? "promise" : "non-promise", "\n"; # -> "non-promise"
 print $b, "\n"; # -> "0.5"

 # Note that lazy evaluation and mutation usually doesn't mix well -
 # lazy programs better be purely functional. Here $tot depends not
 # just on the inputs, but also on how many elements were evaluated:
 my $tot=0;
 # `stream_map` is from `FP::Stream` and uses `lazy`
 my $l= stream_map sub {
     my ($x)=@_;
     $tot+=$x;
     $x*$x
 }, list (5,7,8);
 print "$tot\n"; # still 0
 print $l->first, " $tot\n"; # 25 5
 print $l->length, " $tot\n"; # 3 20

=head1 DESCRIPTION

This implements promises, a data type that represents an unevaluated
or evaluated computation. The computation represented by a promise is
only ever evaluated once, after which point its result is saved in the
promise, and subsequent requests for evaluation are simply returning
the saved value.

 $p = lazy { ...... } # returns a promise that represents the computation
                       # given in the block of code

 force $p  # runs the block of code and stores the result within the
           # promise and also returns it

 FORCE $p,$q,$r;
           # in addition to running force, stores back the resulting
           # value into the variable given as argument ($p, $q, and $r
           # respectively (this example forces 3 (possibly) separate
           # values))

 is_promise $x # returns true iff $x holds a promise


=head1 SEE ALSO

https://en.wikipedia.org/wiki/Futures_and_promises

Alternative Data::Thunk, but see note in TODO file about problems.

Alternative Scalar::Defer?

=cut


package FP::Lazy;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(lazy lazyLight force FORCE is_promise);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';


sub lazy (&) {
    bless [$_[0],undef], "FP::Lazy::Promise"
}

# not providing for caching (1-time-only evaluation)
sub lazyLight (&) {
    bless $_[0], "FP::Lazy::PromiseLight"
}

sub is_promise ($) {
    (UNIVERSAL::isa ($_[0], "FP::Lazy::Promise"))
}

sub force ($;$) {
    my ($perhaps_promise,$nocache)=@_;
  LP: {
	if (UNIVERSAL::isa ($perhaps_promise, "FP::Lazy::PromiseLight")) {
	    $perhaps_promise= &$perhaps_promise;
	    redo LP;
	} elsif (UNIVERSAL::isa ($perhaps_promise, "FP::Lazy::Promise")) {
	    if (my $thunk= $$perhaps_promise[0]) {
		my $v= &$thunk;
		unless ($nocache) {
		    $$perhaps_promise[1]= $v;
		    $$perhaps_promise[0]= undef;
		}
		$perhaps_promise= $v;
		redo LP;
	    } else {
		$perhaps_promise= $$perhaps_promise[1];
		redo LP;
	    }
	} else {
	    $perhaps_promise
	}
    }
}

sub FORCE {
    for (@_) {
	$_ = force $_
    }
    wantarray ? @_ : $_[-1]
}

{
    package FP::Lazy::Promise;
    *force= *FP::Lazy::force;
    sub DESTROY {
	# nothing, catch this to prevent it from entering AUTOLOAD
    }
    our $AUTOLOAD; # needs to be declared even though magical
    sub AUTOLOAD {
	my $v= force ($_[0]);
	my $methodname= $AUTOLOAD;
	$methodname =~ s/.*:://;
	# To be able to select special implementations for lazy
	# inputs, select a method with `stream_` prefix if present.
	my $method=
	  ($methodname=~ /^stream_/ ? UNIVERSAL::can($v, $methodname)
	   : UNIVERSAL::can($v, "stream_$methodname")
	     // UNIVERSAL::can($v, $methodname));
	if ($method) {
	    # can't change @_ or it would break 'env clearing' ability
	    # of the method. Thus assign to $_[0], which will effect
	    # our env, too, but so what? XX still somewhat bad.
	    $_[0]= $v; goto $method;
	} else {
	    # XX imitate perl's ~exact error message?
	    die "no method '$methodname' found for object: $v";
	}
    }
}

{
    package FP::Lazy::PromiseLight;
    our @ISA= qw(FP::Lazy::Promise);
}

1
