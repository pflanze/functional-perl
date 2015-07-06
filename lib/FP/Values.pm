#
# Copyright (c) 2013-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License. See the file COPYING.md that came bundled with this
# file.
#

=head1 NAME

FP::Values - utilities to work with Perl's multiple values ("lists")

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package FP::Values;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(fst snd);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

sub fst {
    $_[0]
}

sub snd {
    $_[1]
}

1
