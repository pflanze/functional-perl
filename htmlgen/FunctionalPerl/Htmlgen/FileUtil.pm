#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::Htmlgen::FileUtil

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FunctionalPerl::Htmlgen::FileUtil;
@ISA = "Exporter";
require Exporter;
@EXPORT      = qw();
@EXPORT_OK   = qw(existingpath_or create_parent_dirs);
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental "signatures";

use Sub::Call::Tail;

# lib?
sub existingpath_or(@paths) {
    for (@paths) {
        return $_ if -e $_
    }
    die "none of the paths exist: @paths";
}

use POSIX qw(EEXIST ENOENT);
use Chj::xperlfunc qw(dirname xmkdir);

# XX how is this different from xmkdir_p ?
sub create_parent_dirs($path0, $path0_to_outpath) {
    my $path0   = dirname $path0;
    my $outpath = &$path0_to_outpath($path0);
    if (mkdir $outpath) {

        # ok, return
    } elsif ($! == EEXIST) {

        # ok, return
    } elsif ($! == ENOENT) {
        create_parent_dirs($path0, $path0_to_outpath);
        xmkdir $outpath;
    } else {
        die "mkdir '$outpath': $!";
    }
}

1
