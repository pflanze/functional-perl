#
# Copyright (c) 2003-2014 Christian Jaeger, copying@christianjaeger.ch
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


=cut


package Chj::xtmpfile;
@ISA='Exporter';
require Exporter;
@EXPORT= qw(xtmpfile);
use strict; use warnings; use warnings FATAL => 'uninitialized';

use Chj::IO::Tempfile;

sub xtmpfile {
    unshift @_,'Chj::IO::Tempfile';
    goto &Chj::IO::Tempfile::xtmpfile;
}

1
