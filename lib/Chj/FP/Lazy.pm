#
# Copyright 2013-2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::FP::Lazy

=head1 SYNOPSIS

 use Chj::FP::Lazy;

 my $a = Delay { 1 / 0 };
 print Force $a # -> Illegal division by zero

 my $b = Delay { warn "evaluation happening"; 1 / 2 };
 print is_promise $b ? "promise" : "non-promise", "\n"; # -> "promise"
 print Force ($b), "\n"; # shows the warning, and "0.5"
 # $b is still a promise at this poing (although an evaluated one):
 print is_promise $b ? "promise" : "non-promise", "\n"; # -> "promise"

 # The following stores result of `Force $b` back into $b
 FORCE $b; # does not show the warning anymore as evaluation happened already
 print is_promise $b ? "promise" : "non-promise", "\n"; # -> "non-promise"
 print $b, "\n"; # -> "0.5"

=head1 DESCRIPTION

This implements promises, a data type that represents an unevaluated
or evaluated computation. The computation represented by a promise is
only ever evaluated once, after which point its result is saved in the
promise, and subsequent requests for evaluation are simply returning
the saved value.

 $p = Delay { ...... } # returns a promise that represents the computation
                       # given in the block of code

 Force $p  # runs the block of code and stores and returns its result

 FORCE $p  # in addition to running Force, stores back the resulting
           # value into $p

 is_promise $x # returns true iff $x holds a promise


=head1 SEE ALSO

https://en.wikipedia.org/wiki/Futures_and_promises

Alternative Data::Thunk, but see note in TODO file about problems.

Alternative Scalar::Defer?

=cut


package Chj::FP::Lazy;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Delay DelayLight Force FORCE is_promise);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';


sub Delay (&) {
    bless [$_[0],undef], "Chj::FP::Lazy::Promise"
}

# not providing for caching (1-time-only evaluation)
sub DelayLight (&) {
    bless $_[0], "Chj::FP::Lazy::PromiseLight"
}
@Chj::FP::Lazy::PromiseLight::ISA= qw(Chj::FP::Lazy::Promise);

sub is_promise ($) {
    (UNIVERSAL::isa ($_[0], "Chj::FP::Lazy::Promise"))
}

sub Force ($;$) {
    my ($perhaps_promise,$nocache)=@_;
  LP: {
	if (UNIVERSAL::isa ($perhaps_promise, "Chj::FP::Lazy::PromiseLight")) {
	    $perhaps_promise= &$perhaps_promise;
	    redo LP;
	} elsif (UNIVERSAL::isa ($perhaps_promise, "Chj::FP::Lazy::Promise")) {
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
	$_ = Force $_
    }
}

{
    package Chj::FP::Lazy::Promise;
}

1
