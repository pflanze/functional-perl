# Wed Jun  4 02:19:29 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself.
#
# $Id$

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
    unshift @_,'Chj::IO::Tempfile'; # pass einfach auf!!! dassdich nicht vertippst hier.
    goto &Chj::IO::Tempfile::xtmpfile;
}

1;
