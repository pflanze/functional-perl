#
# Copyright (c) 2003-2014 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::IO::Pipe

=head1 SYNOPSIS

=head1 DESCRIPTION

Inherits from Chj::IO::File.

=cut


package Chj::IO::Pipe;
@ISA= "Chj::IO::File";
require Chj::IO::File;
use strict; use warnings; use warnings FATAL => 'uninitialized';

sub quotedname {
    "pipe"
}

1;
