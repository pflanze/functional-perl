#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
# Published under the same terms as perl itself
#

=head1 NAME

PXML::SVG

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package PXML::SVG;
@ISA="Exporter"; require Exporter;

use strict; use warnings; use warnings FATAL => 'uninitialized';

use PXML::Element;

our $tags=
  [
   'svg',
   'path',
   'a',
   # XXX unfinished! Many more of course.
  ];


sub svg {
    my $attrs= ref $_[0] eq "HASH" ? shift : {};
    my $attrs2= +{%$attrs};
    $$attrs2{xmlns}= "http://www.w3.org/2000/svg";
    $$attrs2{"xmlns:xlink"}= "http://www.w3.org/1999/xlink";
    PXML::SVG::SVG($attrs2, @_)
}


# XX mostly copy paste from PXHTML. Abstract away, please.

our $nbsp= "\xa0";

our $funcs=
  [
   map {
       my $tag=$_;
       [
	uc $tag,
	sub {
	    my $atts= ref($_[0]) eq "HASH" ? shift : undef;
	    PXML::PSVG->new($tag, $atts, [@_]);
	}
       ]
   } @$tags
  ];

for (@$funcs) {
    my ($name, $fn)=@$_;
    no strict 'refs';
    *{"PXML::SVG::$name"}= $fn
}

our @EXPORT_OK= ('svg', '$nbsp', map { $$_[0] } @$funcs);
our %EXPORT_TAGS=(all=>\@EXPORT_OK);

{
    package PXML::PSVG;
    our @ISA= "PXML::Element";
    # serialize to HTML5 compatible representation: -- nope, not
    # necessary for SVG, ok? Assuming XHTML always? And different tags
    # anyway, ok?
}


1
