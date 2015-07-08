#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Htmlgen::Toc - building a table of contents

=head1 SYNOPSIS

 use Htmlgen::Toc qw(map_with_toc);
 # pass `\&map_with_toc` as part of a mapping table to
 # `pxml_map_elements`

=head1 DESCRIPTION

Expands this syntax in a PXML document:

<with_toc> <h2>..</h2> <h3>..</h3>.. <h2>..</h2> </with_toc>

=cut


package Htmlgen::Toc;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(map_with_toc);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
use Sub::Call::Tail;

use FP::StrictList;
use FP::List;
use Chj::TEST;
use PXML::XHTML ":all";
use FP::Stream qw(stream_mixed_state_fold_right);
use PXML ":all";
use FP::Predicates qw(is_natural);

fun rindices_numberstring ($rindices) {
    is_null $rindices ? "" :
      $rindices->reverse->map(fun($i){"$i."})->strings_join ("")." ";
}

TEST { rindices_numberstring (list ()) }     "";
TEST { rindices_numberstring (list (2,1)) }  "1.2. ";

{
    package PFLANZE::TocNodeBase;
    use FP::StrictList;
    use FP::Predicates;
    use FP::List;
    use PXML::XHTML ":all";

    use FP::Struct [[*is_strictlist, "subnodes"]];

    method subnodes_length () {
	$self->subnodes->length
    }

    method subnodes_add ($node) {
	is_instance_of $node, "PFLANZE::TocNode"
	  or die "wrong type";
	# (^ XX so poor, neither do I have a TypedList yet, nor the
	# syntax to add it to the method declaration)
	$self->subnodes_update(fun ($l){ cons $node, $l })
    }

    method subnodes_head_update ($fn) {
	my $ss= $self->subnodes;
	if (is_null $ss) {
	    die "skipped level" ## nicer message and all?
	} else {
	    $self->subnodes_set (cons (&$fn ($ss->first), $ss->rest))
	}
    }

    method level_add ($levelsdown, $node) {
	is_natural $levelsdown or die "wrong type: $levelsdown";
	if ($levelsdown > 1) {
	    $self->subnodes_head_update (fun ($subnode) {
		$subnode->level_add ($levelsdown - 1, $node)
	    })
	} else {
	    $self->subnodes_add ($node)
	}
    }

    # just for debugging? $indices is a list of 1-based indices
    method ref ($indices) {
	if (is_null $indices) {
	    $self
	} else {
	    my ($i,$indices1)= $indices->first_and_rest;
	    my $subnodes= $self->subnodes;
	    $subnodes->ref ($subnodes->length - $i)->ref ($indices1)
	}
    }

    # used during document mapping (while the toc is collected)
    method numberstring () {
	my $ss= $self->subnodes;
	my $len= $ss->length;
	# the first is the one that was added last
	$len ? $len . "." . $ss->first->numberstring
	  : "";
	# (O(n^2) complexity)
    }

    # build the TOC html. Need to get the numberstring differently
    # now.
    method html_with_parents ($rindices) {
	my $maybe_name= $self->name;
	my $shown= [Htmlgen::Toc::rindices_numberstring ($rindices),
		    $self->header_pxml_for_toc ];
	DIR({class=> "toc"},
	    (defined $maybe_name ? A({href=> "#".$maybe_name}, $shown)
	     : $shown),
	    $self->subnodes->array__reverse__map_with_length
	    (fun ($node,$num) {
		LI ($node->html_with_parents(cons $num, $rindices))
	    }))
    }

    _END_
}

{
    package PFLANZE::TocNode;
    use FP::Predicates "is_string";
    use PXML "is_pxml_element";
    use FP::List;

    use FP::Struct [[*is_string, "name"], # as used in the <a name="">
                                          # already in the document
		    [*is_pxml_element, "header"]
		   ],
		     "PFLANZE::TocNodeBase";

    method header_pxml_for_toc () {
	# XX keep some formatting?
	$self->header->text
    }

    _END_
}

{
    package PFLANZE::TocRootNode;
    use FP::List;
    use PXML::XHTML ":all";

    use FP::Struct ["header_pxml_for_toc"], "PFLANZE::TocNodeBase";

    method name () { undef }

    method html () {
	DIV({class=> "toc_box"},
	    $self->html_with_parents (null))
    }

    _END__
}


our $empty_toc= PFLANZE::TocRootNode->new
  (strictnull,
   H3 ({class=> "toc_title"}, "Contents"));

sub tocnode ($$) {
    my ($name,$header)=@_;
    PFLANZE::TocNode->new(strictnull, $name, $header);
}

our $ttoc;
TEST {
    my $t1= $empty_toc->level_add (1, tocnode("a", H1("First")));
    my $t11= $t1->level_add (2, tocnode("b", H2("Sub-First")));
    my $t2= $t11->level_add (1, tocnode("c", H1("Second")));
    $ttoc= $t2;
    [ map { $_->numberstring } $t11, $t2 ]
}
  ['1.1.', '2.'];

TEST {
    my $t_paths= list (list(1), list(2), list(1,1));
    $t_paths->map (fun ($path) { $ttoc->ref ($path)-> name }) ->array }
  [qw(a c b)];

TEST { $ttoc->html->string }
  '<div class="toc_box">'
  .'<dir class="toc"><h3 class="toc_title">Contents</h3>'
  .  '<li><dir class="toc"><a href="#a">1. First</a>'
  .    '<li><dir class="toc"><a href="#b">1.1. Sub-First</a></dir></li>'
  .  '</dir></li>'
  .  '<li><dir class="toc"><a href="#c">2. Second</a></dir></li>'
  .'</dir></div>';


fun process__with_toc__body ($body, $first_level, $toc, $parents) {
    # -> (processed_body, toc)
    stream_mixed_state_fold_right
      (
       fun ($v,$toc,$rest) {
	   if (is_pxml_element ($v)) {
	       if (my ($_level)= $v->name =~ /^[hH](\d+)$/s) {
		   my $level= $_level - $first_level + 1;
		   is_natural $level
		     or die "The given <with_toc> tag dictates that the ".
		       "top-most header level is '$first_level', but ".
			 "encountering <".$v->name.">";

		   my $anchor= $parents->find (fun ($e) {
		       $e->name eq "a" and $e->maybe_attribute("name")
		   }) // die "bug, missing anchor element";

		   my $toc= $toc->level_add
		     ($level,
		      tocnode ($anchor->maybe_attribute("name"), $v));

		   my ($tail, $toc2)= &$rest ($toc);

		   (cons ($v->body_update
			  (fun ($body)
			   { cons ($toc->numberstring." ", $body) }),
			  $tail),
		    $toc2)
	       } else {
		   # map $v's body
		   my ($body2, $toc2)= process__with_toc__body
		     ($v->body, $first_level, $toc,
		      cons ($v, $parents));

		   my ($tail, $toc3)= &$rest ($toc2);

		   (cons ($v->body_set ($body2), $tail),
		    $toc3)
	       }
	   } else {
	       my ($tail, $toc2)= &$rest ($toc);
	       (cons ($v, $tail), $toc2)
	   }
       },
       fun ($toc) {
	   # return counter back up the chain
	   (null, $toc)
       },
       $body)->($toc);
}

TEST {
    my ($body,$toc)= process__with_toc__body (["foo"], 1, $empty_toc, null);
    [ $body->string, $toc->html->string ]
}
  [
   'foo',
   '<div class="toc_box"><dir class="toc"><h3 class="toc_title">Contents</h3></dir></div>'
  ];

TEST {HTML((process__with_toc__body
	    ["foo", A({name=>"a"}, H1("hed")),"bar"],
	    1,
	    $empty_toc, null)[0])->string}
  '<html>foo<a name="a"><h1>1. hed</h1></a>bar</html>';

TEST {HTML((process__with_toc__body
	    ["foo", A({name=>"a"}, H1("hed")),P("bar")],
	    1,
	    $empty_toc, null)[0])->string}
  '<html>foo<a name="a"><h1>1. hed</h1></a><p>bar</p></html>';

TEST {HTML((process__with_toc__body
	    [cons "foo", [A({name=>"a"}, H1("hed")),
			  A({name=>"b"}, H2("hud")),
			  ["",P("bar")]]],
	    1,
	    $empty_toc, null)[0])->string}
  '<html>foo<a name="a"><h1>1. hed</h1></a><a name="b"><h2>1.1. hud</h2></a><p>bar</p></html>';

TEST {HTML ((process__with_toc__body
	     [" ", P ("blabla"), A({name=>"a"}, H1 ("for one"))],
	     1,
	     $empty_toc, null)
	    [0])->string}
  '<html> <p>blabla</p><a name="a"><h1>1. for one</h1></a></html>';


# map <with_toc> element
fun map_with_toc ($e, $uplist) {
    my ($body, $toc)=
      process__with_toc__body ($e->body,
			       $e->maybe_attribute("level") // 2,
			       $empty_toc, null);
    [ $toc->html, $body]
}


1
