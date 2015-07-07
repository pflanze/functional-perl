#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

PXML - functional XML handling, general functions

=head1 SYNOPSIS

 use PXML;
 use PXML::XHTML;
 is_pxml_element P() # => 1

=head1 DESCRIPTION

General Functions for the PXML libraries.

=head1 SEE ALSO

L<PXML::Element>, L<PXML::Tags>, L<PXML::SVG>, L<PXML::XHTML>,
L<PXML::HTML5>, L<PXML::Util>, L<PXML::Serialize>,
L<http://functional-perl/>

=cut


package PXML;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(is_pxml_element);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use PXML::Element;

use FP::Predicates 'instance_of';

sub is_pxml_element ($); *is_pxml_element= instance_of("PXML::Element");

1
