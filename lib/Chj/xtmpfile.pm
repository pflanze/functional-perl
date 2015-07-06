#
# Copyright 2003-2014 by Christian Jaeger, copying@christianjaeger.ch
# Published under the same terms as perl itself
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
use strict;

use Chj::IO::Tempfile;

sub xtmpfile {
    unshift @_,'Chj::IO::Tempfile';
    goto &Chj::IO::Tempfile::xtmpfile;
}

1
