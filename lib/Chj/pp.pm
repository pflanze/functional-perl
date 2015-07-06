#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License. See the file COPYING.md that came bundled with this
# file.
#

=head1 NAME

Chj::pp -- pretty printing as a debugging help

=head1 SYNOPSIS

 use Chj::pp;

 print pp (1/2) + 1, "\n"; # prints "0.5\n" to stderr then "1.5\n" to stdout

 print pp_ ("x", 1/2) + 1, "\n"; # prints "x: 0.5\n" to stderr then see above

=head1 DESCRIPTION


=cut


package Chj::pp;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(pp pp_);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use Data::Dumper;
use Chj::TerseDumper;

sub Dump {
    @_ > 1 ? Dumper(@_) : TerseDumper(@_)
}

sub pp {
    print STDERR Dump (@_);
    wantarray ? @_ : $_[-1]
}

sub pp_ {
    my $msg=shift;
    print STDERR "$msg:", (@_>1 ? "\n" : " "), Dump (@_);
    wantarray ? @_ : $_[-1]
}


1
