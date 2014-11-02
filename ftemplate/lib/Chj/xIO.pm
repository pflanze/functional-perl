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
@EXPORT=qw(xprint xprintln);
@EXPORT_OK=qw(xgetfile_utf8 xputfile_utf8);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

sub xprint {
    my $fh= (ref($_[0]) eq "GLOB" or UNIVERSAL::isa($_[0],"IO")) ? shift : *STDOUT{IO};
    print $fh @_
      or die "printing to $fh: $!"
}

sub xprintln {
    my $fh= (ref($_[0]) eq "GLOB" or UNIVERSAL::isa($_[0],"IO")) ? shift : *STDOUT{IO};
    print $fh @_,"\n"
      or die "printing to $fh: $!"
}


# better place for these?

use Chj::xopen ":all";

sub xgetfile_utf8 ($) {
    my ($path)=@_;
    my $in= xopen_read ($path);
    binmode $in, ":utf8" or die;
    $in->xcontent
}

sub xputfile_utf8 ($$) {
    my ($path,$str)=@_;
    my $out= xopen_write($path);
    binmode $out, ":utf8" or die;
    $out->xprint($str);
    $out->xclose;
}



1
