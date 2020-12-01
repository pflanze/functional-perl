#
# Copyright (c) 2004-2020 Christian Jaeger, copying@christianjaeger.ch
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
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT = qw(chompspace);

#@EXPORT_OK = qw();

use FP::Carp;

sub chompspace {
    @_ == 1 or fp_croak_arity 1;
    my ($str) = @_;
    $str =~ s/^\s+//s;
    $str =~ s/\s+\z//s;
    $str
}

*Chj::chompspace = \&chompspace;

1;
