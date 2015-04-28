#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::FP::Lazy

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FP::Lazy;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Delay DelayLight Force FORCE promiseP);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';


sub Delay (&) {
    bless [$_[0],undef], "Chj::FP::Lazy::Promise"
}

# not providing for caching (1-time-only evaluation)
sub DelayLight (&) {
    bless $_[0], "Chj::FP::Lazy::PromiseLight"
}
@Chj::FP::Lazy::PromiseLight::ISA= qw(Chj::FP::Lazy::Promise);

sub promiseP ($) {
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
