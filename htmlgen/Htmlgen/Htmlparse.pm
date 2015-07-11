#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Htmlgen::Htmlparse

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Htmlgen::Htmlparse;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(htmlparse);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
use Sub::Call::Tail;

use HTML::TreeBuilder;
use PXML::Element;


fun htmlparse_raw ($htmlstr,$whichtag) {
    my $t= HTML::TreeBuilder->new;
    $t->ignore_unknown(0); # allow <with_toc> elements
    $t->parse_content ($htmlstr);
    my $e= $t->elementify;
    # (^ actually mutates $t into the HTML::Element object already, ugh)
    $e->find_by_tag_name($whichtag)
}


# convert it to PXML
fun htmlmap ($e) {
    my $name= lc($e->tag);
    my $atts={};
    for ($e->all_external_attr_names) {
	next if $_ eq "/";
	die "att name '$_'" unless /^\w+\z/s;
	$$atts{lc $_}= $e->attr($_);
    }
    PXML::Element->new
	($name,
	 $atts,
	 [
	  map {
	      if (ref $_) {
		  # another HTML::Element
		  no warnings "recursion";# XX should rather sanitize input?
		  htmlmap ($_)
	      } else {
		  # a string
		  $_
	      }
	  } @{$e->content||[]}
	 ]);
}

# parse HTML string to PXML
fun htmlparse ($str,$whichtag) {
    htmlmap (htmlparse_raw ($str,$whichtag))
}


1
