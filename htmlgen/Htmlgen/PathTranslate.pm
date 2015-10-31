#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Htmlgen::PathTranslate

=head1 SYNOPSIS

=head1 DESCRIPTION

Configurable source path (.md suffix) to website path (.xhtml suffix
or similar, index instead of README etc.) mapper.

=cut


package Htmlgen::PathTranslate;

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
use Sub::Call::Tail;
use Chj::TEST;
use FP::Predicates;
use Chj::xperlfunc qw(dirname basename);
use Htmlgen::PathUtil qw(path_path0_append);
use FP::Div qw(identity);
use Htmlgen::default_config;
use FP::Show;

our $t= __PACKAGE__->new_(is_indexpath0=> $$default_config{is_indexpath0},
			  downcaps=> 1);

fun t_if_suffix_md_to_html ($in,$for_title=0) {
    $t->if_suffix_md_to_html ($in, $for_title,
		       sub {["then",@_]},
		       sub{["otherwise",@_]})
}

fun is_allcaps ($str) {
    not $str=~ /[a-z]/
}



use FP::Struct [[*is_procedure, "is_indexpath0"],
		[*is_boolean, "downcaps"],
	       ];


method is_md ($path) {
    $path=~ /\.md$/s
}

method if_suffix_md_to_html ($path0,$for_title,$then,$otherwise) {
    if (!$for_title and $$self{is_indexpath0}->($path0)) {
	tail &$then (path_path0_append (dirname($path0), "index.xhtml"))
    } else {
	if ($path0=~ s/(.*?)([^\/]*)\.md$/$1$2.xhtml/) {
	    tail &$then
	      ($$self{downcaps} && is_allcaps ($2) ? $1.lc($2).".xhtml"
	       : $path0);
	} else {
	    tail &$otherwise($path0)
	}
    }
}


TEST{t_if_suffix_md_to_html "README.md"}['then','index.xhtml'];
TEST{t_if_suffix_md_to_html "README.md",1}['then','readme.xhtml'];
# ^ kinda stupid hack.
TEST{t_if_suffix_md_to_html "Foo/index.md"}['then','Foo/index.xhtml'];
TEST{t_if_suffix_md_to_html "Foo/README.md"}['then','Foo/index.xhtml'];
TEST{t_if_suffix_md_to_html "Foo/READMe.md"}['then','Foo/index.xhtml'];
# ^ XX really?
TEST{t_if_suffix_md_to_html "Foo/MY.css"}['otherwise','Foo/MY.css'];


method possibly_suffix_md_to_html ($path,$for_title=0) {
    $self->if_suffix_md_to_html
      ($path,
       $for_title,
       *identity,
       *identity)
}

method xsuffix_md_to_html ($path0,$for_title) {
    $self->if_suffix_md_to_html($path0, $for_title,
		      *identity,
		      sub{die "file does not end in .md: ".show($path0)})
}

TEST{ $t->possibly_suffix_md_to_html ("foo") } "foo";
TEST{ $t->possibly_suffix_md_to_html ("foo.md") } "foo.xhtml";
TEST_EXCEPTION{ $t->xsuffix_md_to_html ("foo", 0) } "file does not end in .md: 'foo'";


_END_
