#
# Copyright (c) 2007 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License. See the file COPYING.md that came bundled with this
# file.
#

=head1 NAME

Chj::Unix::exitcode

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Unix::exitcode;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(exitcode);
@EXPORT_OK=qw(exitcode);
%EXPORT_TAGS=(all=>\@EXPORT_OK);

use strict;

use Chj::Unix::Exitcode;

sub exitcode ( $ ) {
    my ($code)=@_;
    Chj::Unix::Exitcode->new($code)->as_string;
}

*Chj::Unix::exitcode= \&exitcode;

1
