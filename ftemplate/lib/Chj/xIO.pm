#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::xIO - exception-throwing I/O wrappers and utilities

=head1 SYNOPSIS

=head1 DESCRIPTION

Much simpler procedures than my extensive OO based Chj::IO::File and
Chj::xopen modules.

=cut


package Chj::xIO;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(xprint);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

sub xprint {
    my $fh=shift;
    print $fh @_
      or die "printing to $fh: $!"
}


1
