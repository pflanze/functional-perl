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
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
use Sub::Call::Tail;

use Chj::TEST;
use Htmlgen::UriUtil qw(URI_is_internal);
use Htmlgen::PathUtil qw(path_diff path_add);
use PXML qw(is_pxml_element);
use PXML::XHTML ":all";
use HTML::TreeBuilder;
use Chj::xperlfunc qw(dirname);
use FP::Stream ":all";
use FP::fix;
use FP::Predicates;


fun htmlparse_raw ($htmlstr,$whichtag) {
    my $t= HTML::TreeBuilder->new;
    $t->ignore_unknown(0); # allow <with_toc> elements
    $t->parse_content ($htmlstr);
    my $e= $t->elementify;
    # (^ actually mutates $t into the HTML::Element object already, ugh)
    $e->find_by_tag_name($whichtag)
}



use FP::Struct [[instance_of("Htmlgen::PathTranslate"), "pathtranslate"]];


# convert it to PXML
method htmlmap ($e,$selfpath0,$filesinfo) {
    my $name= lc($e->tag);
    my $atts={};
    for ($e->all_external_attr_names) {
	next if $_ eq "/";
	die "att name '$_'" unless /^\w+\z/s;
	$$atts{lc $_}= $e->attr($_);
    }

    # fix internal .md links; should this be moved to the PXML mapping
    # phase now?
    if ($name eq "a"
	and URI_is_internal(my $uri= URI->new($$atts{href}))) {

	# check or find target, then convert to xhtml suffix
	my $path= $uri->path;

	# '//' feature (see doc-formatting.txt)
	if ($$atts{href} =~ m|^//|s) {
	    my ($op)= $uri->opaque() =~ m|^//([^/]+)$|s
	      or die "bug";
	    if (my ($p0)= $filesinfo->perhaps_filename_to_path0($op)) {
		$path= path_diff ($selfpath0,$p0); # mutation
	    } else {
		warn "unknown link target '$op' (from '$$atts{href}')";
		$path= path_diff ($selfpath0, "UNKNOWN/$op");
	    }
	    $uri->opaque(""); # mutation
	} else {
	    if (length $path) {
		my $p0= path_add(dirname ($selfpath0), $path);
		$p0=~ s|^\./||;#hack. grr y
		if ($filesinfo->all_path0_exists($p0)) {
		    $filesinfo->all_path0_used_inc($p0);
		} else {
		    warn "link target does not exist: '$p0' ".
		      "('$path' from '$selfpath0', link '$$atts{href}')";
		    #use Chj::repl;repl;
		}
	    }
	}
	if (length $path) {
	    $uri->path($self->pathtranslate->possibly_suffix_md_to_html ($path));
	}
	$$atts{href}= "$uri";# mutation.
    }

    PXML::Element->new
	($name,
	 $atts,
	 [
	  map {
	      if (ref $_) {
		  # another HTML::Element
		  no warnings "recursion";# XX should rather sanitize input?
		  $self->htmlmap ($_,$selfpath0,$filesinfo)
	      } else {
		  # a string
		  $_
	      }
	  } @{$e->content||[]}
	 ]);
}

# parse HTML string to PXML
method htmlparse ($str,$whichtag,$selfpath0,$filesinfo) {
    $self->htmlmap (htmlparse_raw ($str,$whichtag), $selfpath0, $filesinfo)
}


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



_END_
