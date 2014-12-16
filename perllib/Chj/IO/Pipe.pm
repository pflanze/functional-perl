# Thu May 29 21:20:31 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself.
#
# $Id$

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
