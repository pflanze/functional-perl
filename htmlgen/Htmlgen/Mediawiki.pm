#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Htmlgen::Mediawiki

=head1 SYNOPSIS

=head1 DESCRIPTION

Expand `[[ ]]` in markdown source text into standard markdown format.

=cut


package Htmlgen::Mediawiki;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(mediawiki_expand);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
use Sub::Call::Tail;
use Chj::chompspace;
use Chj::TEST ":all";
use PXML::XHTML ":all";

# and for text display we need to *decode* URIs..
# COPY from chj-bin's `urldecode`
use Encode;
sub url_decode {
    my ($str)=@_;
    my $u= URI->new($str);
    my $str2= $u->uri_unescape;
    decode("utf-8", $str2, Encode::FB_CROAK)
}

# escape [ ] for markdown; XX is this correct?
fun squarebracked_escape ($str) {
    $str=~ s%([\[\]])%\\$1%sg;
    $str
}


fun mediawiki_expand ($str) {
    my $res=[];
    my $lastpos= 0;
    while ($str=~ m%(?<=[^\\])\[\[(.*?[^\\])\]\]%sg) {
	my $cont= $1;
	my $pos= pos $str;

	my $matchlen= 2 + length ($cont) + 2;
	my $prelen= $pos-$matchlen-$lastpos;
	push @$res, substr $str, $lastpos, $prelen
	  if $prelen>0;
	$lastpos=$pos;

	$cont=~ s|(?<=[^\\])\\(.)|$1|sg; # remove quoting
	my @parts= map { chompspace $_ } split /(?<=[^\\])\|/, $cont;
	if (@parts==1) {
	    my ($docname_and_perhaps_fragment)= @parts;
	    my $uri= URI->new($docname_and_perhaps_fragment);

	    my $fragment= url_decode $uri->fragment;
	    my $fragmenttext= do {
		if (length $fragment) {
		    my @f= split /,/, $fragment;
		    my $f= shift @f;
		    while (@f and length $f < 20 and length $f[0] < 20) {
			$f.= ",".shift @f;
		    }
		    $f.= ".." if @f;
		    if (length $f > 40) {
			$f= substr ($f, 0, 28). ".."
		    }
		    " ($f)";
		} else {
		    ""
		}
	    };

	    # (Get title of document at path? But may be too long,
	    # probably not a good idea.)

	    # XX use 'opaque' instead of 'path' for the url? for
	    # locations with protocol or so? Or croak about those? Use
	    # opaque for the text, though, ok?
	    my $text= $uri->opaque;
	    $text=~ tr/_/ /;
	    push @$res,
	      A({
		 href=>
		 "//"
		 . $uri->path.".md"
		 . do {
		     my $f= $uri->fragment;
		     length $f ? "#".$f : ""
		 }
		},
		$text.$fragmenttext);
	} elsif (@parts==2) {
	    my ($loc,$text)= @parts;
	    push @$res,
	      A({href=> $loc},
		$text)
	} else {
	    # XX location?...
	    die "more than 2 parts in a wiki style link: '$cont'";
	}
    }

    my $postlen= length($str)-$lastpos;
    push @$res, substr $str, $lastpos, $postlen
      if $postlen > 0;

    $res
}


TEST { mediawiki_expand "<foo>[[bar]] baz</foo>" }
  ['<foo>', A({href=> "//bar.md"}, "bar"), ' baz</foo>'];

TEST { mediawiki_expand
	 ' [[howto#References (and "mutation"), "variables" versus "bindings"]] ' }
  [' ', A({href=> '//howto.md#References%20(and%20%22mutation%22),%20%22variables%22%20versus%20%22bindings%22'},
	  'howto (References (and "mutation")..)'), ' '];

TEST { mediawiki_expand ' [[Foo#yah\\[1\\]]] ' }
  [' ', A({href=> '//Foo.md#yah[1]'}, 'Foo (yah[1])'), ' '];

TEST { mediawiki_expand ' [[Foo#(yah)\\[1\\]|Some \\[text\\]]] ' }
  [' ', A({href=> 'Foo#(yah)[1]'}, 'Some [text]'), ' ']; # note: no // and .md added to Foo!



1
