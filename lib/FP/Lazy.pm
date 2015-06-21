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

 # Also note that `local` does mutation (even if in a somewhat
 # controlled way):
 our $foo= "";
 sub moo {
     my ($bar)=@_;
     local $foo= "Hello";
     lazy { "$foo $bar" }
 }
 moo ("you")->force  # returns " you"


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


=head1 NAMING

The name `lazy` for the delaying form was chosen because it seems what
most frameworks for functional programming on non-functional
programming languages are using, as well as Ocaml. We don't want to
stand in the way of what people expect, after all.

Scheme calls the lazy evaluation form `delay`. This seems to make
sense, as that's a verb, unlike `lazy`. There's a conceptually
different way to introduce lazyness, which is to change the language
to be lazy by default, and `lazy` could be misunderstood to be a form
that changes the language in its scope to be that. Both for this
current (slight?) risk for misinterpretation, and to reserve it for
possible future implementation of this latter feature, it seems to be
wise to use `delay` and not `lazy` for what this module offers.

What should we do?

(To experiment with the style, or in case you're stubborn, you can
explicitely import `delay` or import the `:all` export tag to get it.)

=head1 TODO

If the thunk of a promise throws an exception, the promise will remain
unevaluated. This is the easiest (and most efficient) thing to do, but
there remains a question about the safety: if the data source is
read-once (like reading lines from files), and the exception happens
after the read, then forcing the promise again will fetch and store
the next line, hence a line will be lost. Since exceptions can happen
because of out of memory conditions or from signal handlers, this will
be of real concern in some situations.

Provide safe promises for these situations? (But that would mean that
they need to be implemented in C as Perl does not offer the features
to implement them safely, correct?)

=head1 SEE ALSO

https://en.wikipedia.org/wiki/Futures_and_promises

Alternative Data::Thunk, but see note in TODO file about problems.

Alternative Scalar::Defer?

=cut


package FP::Lazy;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(lazy lazyLight force FORCE is_promise);
@EXPORT_OK=qw(delay);
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
    length ref $_[0] ? UNIVERSAL::isa ($_[0], "FP::Lazy::Promise") : ''
}

sub delay (&);  *delay = \&lazy;
sub delayLight (&); *delayLight= \&lazyLight;


sub force ($;$) {
    my ($perhaps_promise,$nocache)=@_;
  LP: {
	if (length (my $r= ref $perhaps_promise)) {
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

use Chj::TEST;

TEST {
    our $foo= "";
    sub moo {
	my ($bar)=@_;
	local $foo= "Hello";
	lazy { "$foo $bar" }
    }
    moo ("you")->force
}
  " you";


1
