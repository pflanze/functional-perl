#
# Copyright 2014 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::PSVG

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::PSVG;
@ISA="Exporter"; require Exporter;

use strict; use warnings FATAL => 'uninitialized';

use Chj::PXML;

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
    Chj::PSVG::SVG($attrs2, @_)
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
	    Chj::PXML::PSVG->new($tag, $atts, [@_]);
	}
       ]
   } @$tags
  ];

for (@$funcs) {
    my ($name, $fn)=@$_;
    no strict 'refs';
    *{"Chj::PSVG::$name"}= $fn
}

our @EXPORT_OK= ('svg', '$nbsp', map { $$_[0] } @$funcs);
our %EXPORT_TAGS=(all=>\@EXPORT_OK);

{
    package Chj::PXML::PSVG;
    our @ISA= "Chj::PXML";
    # serialize to HTML5 compatible representation: -- nope, not
    # necessary for SVG, ok? Assuming XHTML always? And different tags
    # anyway, ok?
}


1
