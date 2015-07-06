#
# Copyright (c) 2003-2014 Christian Jaeger, copying@christianjaeger.ch
# Published under the same terms as perl itself
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
use strict;

sub quotedname {
    "pipe"
}

1;
