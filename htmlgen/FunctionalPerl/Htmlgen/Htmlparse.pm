#
# Copyright (c) 2014-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::Htmlgen::Htmlparse

=head1 SYNOPSIS

    use FunctionalPerl::Htmlgen::Htmlparse qw(htmlparse);
    my $b = htmlparse '<p>hi</p> <p>there!', 'body';
    is ref($b), 'PXML::_::XHTML';
    is $b->string, '<body><p>hi</p><p>there!</p></body>';

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FunctionalPerl::Htmlgen::Htmlparse;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental "signatures";
use Sub::Call::Tail;
use Exporter "import";

our @EXPORT      = qw();
our @EXPORT_OK   = qw(htmlparse);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Docstring;
use HTML::TreeBuilder;

#use PXML::Element;
use PXML::XHTML;
use Chj::TEST;

sub htmlparse_raw ($htmlstr, $whichtag) {
    my $t = HTML::TreeBuilder->new;
    $t->ignore_unknown(0);    # allow <with_toc> elements
    $t->parse_content($htmlstr);
    my $e = $t->elementify;

    # (^ actually mutates $t into the HTML::Element object already, ugh)
    $e->find_by_tag_name($whichtag)
}

sub htmlmap($e) {
    __ '(HTML::Element) -> PXML::_::XHTML '
        . '-- convert output from HTML::TreeBuilder to PXML::XHTML (PXML::Element)';
    my $name = lc($e->tag);
    my $atts = {};
    for ($e->all_external_attr_names) {
        next if $_ eq "/";
        die "att name '$_'" unless /^\w+\z/s;
        $$atts{ lc $_ } = $e->attr($_);
    }

    # XX unsafe, if we don't check that a corresponding constructor
    # exists! Could fall back to just PXML::Element (which
    # PXML::_::XHTML is):
    PXML::_::XHTML->new(
        $name, $atts,
        [
            map {
                if (ref $_) {

                    # another HTML::Element
                    no warnings "recursion";  # XX should rather sanitize input?
                    htmlmap($_)
                } else {

                    # a string
                    $_
                }
            } @{ $e->content || [] }
        ]
    );
}

sub htmlparse ($str, $whichtag) {
    __ '($str,$whichtag) -> PXML::Element '
        . '-- parse HTML string to PXML; $whichtag is passed to'
        . ' find_by_tag_name from HTML::TreeBuilder';
    htmlmap(htmlparse_raw($str, $whichtag))
}

# TEST{ htmlparse ('<with_toc><p>abc</p><p>foo</p></with_toc>', "body")
#       ->string }
#   '<body><with_toc><p>abc</p><p>foo</p></with_toc></body>';
# HTML::TreeBuilder VERSION 5.02 drops with_toc here.

TEST {
    htmlparse('x<with_toc><p>abc</p><p>foo</p></with_toc>', "body")->string
}
'<body>x<with_toc><p>abc</p><p>foo</p></with_toc></body>';

# interestingly here it doesn't.

# But perhaps it's best to do like:
TEST {
    htmlparse('<body><with_toc><p>abc</p><p>foo</p></with_toc></body>', "body")
        ->string
}
'<body><with_toc><p>abc</p><p>foo</p></with_toc></body>';

1
