#
# Copyright 2014 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::FP::Div

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FP::Div;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(identity compose);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

sub identity ($) {
    $_[0]
}

# copy from Chj::Env
sub compose {
    my (@fn)= reverse @_;
    sub {
	my (@v)= @_;
	for (@fn) {
	    @v= &$_(@v);
	}
	wantarray ? @v : $v[-1]
    }
}


1
