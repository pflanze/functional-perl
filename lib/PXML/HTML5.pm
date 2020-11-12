#
# Copyright (c) 2013-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

PXML::HTML5

=head1 SYNOPSIS

=head1 DESCRIPTION

currently just provides $html5_void_elements and $html5_void_element_h

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package PXML::HTML5;
@ISA = "Exporter";
require Exporter;
@EXPORT      = qw();
@EXPORT_OK   = qw( $html5_void_elements $html5_void_element_h);
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

# the set of tags that are allowed to be self-closing (<foo/>) without
# semantical changes
our $html5_void_elements = [

    # http://dev.w3.org/html5/markup/syntax.html
    # "The following is a complete list of the void elements in HTML:"
    qw(
        area
        base
        br
        col
        command
        embed
        hr
        img
        input
        keygen
        link
        meta
        param
        source
        track
        wbr
        )
];

our $html5_void_element_h = +{map { $_ => 1 } @$html5_void_elements};

1
