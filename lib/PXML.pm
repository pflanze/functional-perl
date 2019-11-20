#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

PXML - functional XML handling, general functions

=head1 SYNOPSIS

 use PXML qw(is_pxml_element);
 use PXML::XHTML qw(P);

 ok is_pxml_element P();
 is P("Hi <there>")->string, '<p>Hi &lt;there&gt;</p>';

 use PXML ":all";

 is(pxmlbody("foo")->string, "foo");


=head1 DESCRIPTION

General Functions for the PXML libraries.

=head1 SEE ALSO

L<PXML::Element>, L<PXML::Tags>, L<PXML::SVG>, L<PXML::XHTML>,
L<PXML::HTML5>, L<PXML::Util>, L<PXML::Serialize>,
L<http://functional-perl/>

=head1 NOTE

This is alpha software! Read the package README.

=cut


package PXML;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(is_pxml_element);
@EXPORT_OK=qw(pxmlbody pxmlflush is_pxmlflush);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use PXML::Element;

use FP::Predicates 'instance_of';

sub is_pxml_element ($); *is_pxml_element= instance_of("PXML::Element");


{
    package PXML::Body;
    # hacky?.
    *string = *PXML::Element::string;
}

sub pxmlbody {
    bless [@_], "PXML::Body"
}

my $flush= bless [], "PXML::Flush";
sub pxmlflush {
    $flush
}

sub is_pxmlflush ($) {
    my ($v)=@_;
    ref $v and UNIVERSAL::isa($v, "PXML::Flush")
}

# XX make this cleaner:
# - make PXML::Body and PXML::Element inherit both from a base class
# - move `string` there (and perhaps all of serialization)
# - automatically use PXML::Body for bodies? (now that I moved away
#   from requiring bodies to be arrays, though?)


1
