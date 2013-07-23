#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::PXHTML

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::PXHTML;
@ISA="Exporter"; require Exporter;

use strict;

use Chj::PXML;

our $nbsp= "\xa0";

our $tags=
     [
          'a',
          'abbr',
          'acronym',
          'address',
          'applet',
          'area',
          'b',
          'base',
          'basefont',
          'bdo',
          'big',
          'blockquote',
          'body',
          'br',
          'button',
          'caption',
          'center',
          'cite',
          'code',
          'col',
          'colgroup',
          'dd',
          'del',
          'dfn',
          'dir',
          'div',
          'dl',
          'dt',
          'em',
          'fieldset',
          'font',
          'form',
          'h1',
          'h2',
          'h3',
          'h4',
          'h5',
          'h6',
          'head',
          'hr',
          'html',
          'i',
          'iframe',
          'img',
          'input',
          'ins',
          'isindex',
          'kbd',
          'label',
          'legend',
          'li',
          'link',
          'map',
          'menu',
          'meta',
          'noframes',
          'noscript',
          'object',
          'ol',
          'optgroup',
          'option',
          'p',
          'param',
          'pre',
          'q',
          's',
          'samp',
          'script',
          'select',
          'small',
          'span',
          'strike',
          'strong',
          'style',
          'sub',
          'sup',
          'table',
          'tbody',
          'td',
          'textarea',
          'tfoot',
          'th',
          'thead',
          'title',
          'tr',
          'tt',
          'u',
          'ul',
          'var'
     ];

our $funcs=
  [
   map {
       my $tag=$_;
       [
	uc $tag,
	sub {
	    my $atts= ref($_[0]) eq "HASH" ? shift : undef;
	    Chj::PXML::PXHTML->new($tag, $atts, [@_]);
	}
       ]
   } @$tags
  ];

for (@$funcs) {
    my ($name, $fn)=@$_;
    no strict 'refs';
    *{"Chj::PXHTML::$name"}= $fn
}

our @EXPORT_OK= ('$nbsp', map { $$_[0] } @$funcs);
our %EXPORT_TAGS=(all=>\@EXPORT_OK);

{
    package Chj::PXML::PXHTML;
    our @ISA= "Chj::PXML";
}


1
