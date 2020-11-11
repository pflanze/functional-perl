#
# Copyright (c) 2004 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::chompspace

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package Chj::chompspace;
@ISA = "Exporter"; require Exporter;
@EXPORT = qw(chompspace);
#@EXPORT_OK = qw();
use strict; use warnings; use warnings FATAL => 'uninitialized';

sub chompspace($) {
    my ($str) = @_;
    $str =~ s/^\s+//s;
    $str =~ s/\s+\z//s;
    $str
}

*Chj::chompspace= \&chompspace;

1;
