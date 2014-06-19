#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FP2::Lazy

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FP2::Lazy;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Delay DelayLight Force promiseP);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';


sub Delay (&) {
    bless [$_[0],undef], "Chj::FP2::Lazy::Promise"
}

# not providing for caching (1-time-only evaluation)
sub DelayLight (&) {
    bless $_[0], "Chj::FP2::Lazy::PromiseLight"
}
@Chj::FP2::Lazy::PromiseLight::ISA= qw(Chj::FP2::Lazy::Promise);

sub promiseP ($) {
    (UNIVERSAL::isa ($_[0], "Chj::FP2::Lazy::Promise"))
}

sub Force ($;$) {
    my ($perhaps_promise,$nocache)=@_;
  LP: {
	if (UNIVERSAL::isa ($perhaps_promise, "Chj::FP2::Lazy::PromiseLight")) {
	    $perhaps_promise= &$perhaps_promise;
	    redo LP;
	} elsif (UNIVERSAL::isa ($perhaps_promise, "Chj::FP2::Lazy::Promise")) {
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

{
    package Chj::FP2::Lazy::Promise;
}

1
