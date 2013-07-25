#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::PHTML5

=head1 SYNOPSIS

=head1 DESCRIPTION

currently just provides $html5_void_elements and $html5_void_element_h

=cut


package Chj::PHTML5;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw( $html5_void_elements $html5_void_element_h);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

# the set of tags that are allowed to be self-closing (<foo/>) without
# semantical changes
our $html5_void_elements=
  [
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

our $html5_void_element_h=
  +{
    map { $_=> 1} @$html5_void_elements
   };


1
