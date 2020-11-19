#
# Copyright (c) 2003-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::xtmpfile

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::xtmpfile;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter 'import';

our @EXPORT = qw(xtmpfile);

use Chj::IO::Tempfile;

sub xtmpfile {
    unshift @_, 'Chj::IO::Tempfile';
    goto &Chj::IO::Tempfile::xtmpfile;
}

1
