#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

FP::Div - various pure functions

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package FP::Div;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(inc dec square
	      identity
	      Chomp
	      );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Chj::TEST;

# XX should `indentity` pass multiple values, and this be called
# `identity_scalar`? :

sub identity ($) {
    $_[0]
}

sub inc ($) {
    $_[0] + 1
}

sub dec ($) {
    $_[0] - 1
}

sub square ($) {
    $_[0] * $_[0]
}

# is there any better idea than ucfirst to distinguish from the
# builtin? `fchomp` ?
sub Chomp ($) {
    my ($str)=@_;
    chomp $str;
    $str
}

1
