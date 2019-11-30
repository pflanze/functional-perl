#
# Copyright (c) 2014-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::Htmlgen::MarkdownPlus

=head1 SYNOPSIS

    use FunctionalPerl::Htmlgen::MarkdownPlus qw(markdownplus_parse);
    use PXML::XHTML qw(BODY);

    my $mediawikitoken= rand;
    # passed to mediawiki_prepare from FunctionalPerl::Htmlgen::Mediawiki
    my ($h1,$body1)= markdownplus_parse(
          "# Hi\n\nHello [World](http://world).\n", # markdownplusstr
          "Hi too", # alternative_title
          $mediawikitoken);
    is $h1->string, '<h1>Hi</h1>';
    is BODY($body1)->string,
       '<body><p>Hello <a href="http://world">World</a>.</p></body>';


=head1 DESCRIPTION

MarkdownPlus supports what L<Text::Markdown> supports plus:

C<[[foo]]> (mediawiki style) document link syntax (via
L<FunctionalPerl::Htmlgen::Mediawiki>).

C<<with_toc>...</with_toc>> tags to span across text that should
generate a table of contents.


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FunctionalPerl::Htmlgen::MarkdownPlus;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(markdownplus_parse);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
use Sub::Call::Tail;

use Chj::TEST;
use PXML qw(is_pxml_element);
use PXML::XHTML ":all";
use FP::Stream ":all";
use FunctionalPerl::Htmlgen::Htmlparse 'htmlparse';
use Text::Markdown 'markdown';
use FP::Lazy;
use FunctionalPerl::Htmlgen::Mediawiki qw(mediawiki_prepare);


# Return <h1> element if available, and rest.
fun pxml_body_split_h1 ($body) {
    my $b= stream_mixed_flatten $body;
    my ($v,$rest)= $b->first_and_rest;
    if (is_pxml_element $v and $v->name eq "h1") {
        ($v, $rest)
    } else {
        (undef, $body)
    }
}

TEST { [pxml_body_split_h1 ["foo"]] }
  [ undef, ['foo']];

TEST { [pxml_body_split_h1 [H1 ("x"), "foo"]]->[0] }
  H1 ("x");

TEST {
    my ($h1,$rest)=
      pxml_body_split_h1 [H1 ("x", "y"), "foo", B ("bar")];
    [ $h1->string, BODY($rest)->string ]
}
  ['<h1>xy</h1>', '<body>foo<b>bar</b></body>'];


fun markdownplus_parse ($str, $alternative_title, $mediawikitoken) {
    # -> ($h1,$body1)

    my ($str1, $table)= mediawiki_prepare ($str, $mediawikitoken);

    my $htmlstr= markdown ($str1);

    # XX hack: fix '<p><with_toc></p> .. <p></with_toc></p>' before
    # parsing, to avoid losing the with_toc element. Bah.
    $htmlstr=~ s|<p>\s*(</?with_toc[^<>]*>)\s*</p>|$1|sg;

    # `markdown` returns a series of <p> elements etc., not wrapped in
    # any element. Need to wrap it before parsing or it will drop the
    # outmost element if it's (e.g.?) <with_toc>.
    my $bodyelement= htmlparse('<body>'.$htmlstr.'</body>', "body");

    my $body= $bodyelement->body;
    my ($maybe_h1, $rest)= pxml_body_split_h1 ($body);
    ((defined $maybe_h1
      ? ($maybe_h1, $rest)
      : (H1(force ($alternative_title)), $body))
     , $table)
}

1
