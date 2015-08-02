#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Htmlgen::MarkdownPlus

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Htmlgen::MarkdownPlus;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(markdownplus_parse);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
use Sub::Call::Tail;

use Chj::TEST;
use PXML qw(is_pxml_element);
use PXML::XHTML ":all";
use FP::Stream ":all";
use Htmlgen::Htmlparse 'htmlparse';
use Text::Markdown 'markdown';
use FP::TransparentLazy;
use Htmlgen::Mediawiki qw(mediawiki_prepare);


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

TEST{ [pxml_body_split_h1 ["foo"]] }
  [ undef, ['foo']];

TEST{ [pxml_body_split_h1 [H1 ("x"), "foo"]]->[0] }
  H1 ("x");

TEST{
    my ($h1,$rest)=
      pxml_body_split_h1 [H1 ("x", "y"), "foo", B ("bar")];
    [ $h1->string, BODY($rest)->string ]
}
  ['<h1>xy</h1>', '<body>foo<b>bar</b></body>'];


fun markdownplus_parse ($str, $alternative_title, $mediawikitoken) {
    # -> ($h1,$body1)

    my ($str1, $table)=
      mediawiki_prepare ($str, $mediawikitoken);

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
    ((defined $maybe_h1 ? ($maybe_h1, $rest)
      : (H1(force ($alternative_title)), $body)),
     $table)
}

1
