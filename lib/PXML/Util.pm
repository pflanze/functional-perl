#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License. See the file COPYING.md that came bundled with this
# file.
#

=head1 NAME

PXML::Util - utility functions for PXML trees

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package PXML::Util;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(pxml_deferred_map pxml_eager_map
	      pxml_map_elements
	    );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use Chj::TEST;
use FP::List;
use FP::Stream ":all";
use FP::Hash "hash_perhaps_ref";


# Mapping PXML data (works not just on elements).

# Taking value first, like in OO syntax (saves a `flip` or similar
# call, too).


# Deferred mapping, which means that $elementfn receives the original
# element with unmapped body; the body needs to be mapped or replaced
# explicitely.

sub pxml_deferred_map ($$;$$) {
    # Elementfn receives (element, up-list, inferior-map), where
    # up-list is a linked list to the parents and inferior-map is a
    # function of one argument that will do the same as the
    # pxml_deferred_map call (but keep the up-list).  Otherfn is
    # called for leafs (non-sequences) and receives (value, up-list).

    my ($v, $elementfn, $maybe_otherfn, $maybe_uplist)= @_;

    my $make_inferior_map= sub {
	my ($uplist)=@_;
	sub {
	    pxml_deferred_map ($_[0],
			       $elementfn,
			       $maybe_otherfn,
			       $uplist)
	}
    };

    my $uplist= $maybe_uplist // null;

    if (my $r= ref $v) {
	my $uplist2= cons $v, $uplist;
	if (UNIVERSAL::isa ($v, "PXML::Element")) {
	    # XX TCO?
	    &$elementfn ($v,
			 $uplist,
			 &$make_inferior_map ($uplist2))
	} else {
	    stream_map (&$make_inferior_map ($uplist),
			stream_mixed_flatten ($v))
	}
    } else {
	$maybe_otherfn ? &$maybe_otherfn ($v, $uplist) : $v
    }
}


# 'Eager' mapping, meaning, the body is mapped already when $elementfn
# receives an element.

sub pxml_eager_map ($$;$$) {
    # The functions receive (value, up-list), where up-list is a
    # linked list to the parents
    my ($v, $elementfn, $maybe_otherfn, $maybe_uplist)= @_;

    pxml_deferred_map ($v,
		       sub {
			   my ($e, $uplist, $inferior_map)=@_;
			   # XX TCO?
			   &$elementfn($e->body_map ($inferior_map),
				       $uplist)
		       },
		       $maybe_otherfn,
		       $maybe_uplist)
}


sub t_data {
    require PXML::XHTML;
    PXML::XHTML::P("foo",
		   PXML::XHTML::B("bar", undef, stream_iota (5)->take(4)))
}

TEST { t_data->string }
  '<p>foo<b>bar5678</b></p>';

TEST { pxml_eager_map
	 (t_data,
	  sub { $_[0]->name_update(sub {$_[0]."A"})},
	  sub { ($_[0]//"-")."."} )->string }
  '<pA>foo.<bA>bar.-.5.6.7.8.</bA></pA>';

use FP::Ops "the_method";

sub uplist_show {
    my ($uplist)=@_;
    "[".$uplist->map (the_method ("name"))->strings_join("|")."]"
}

TEST { pxml_eager_map
	 (t_data,
	  sub {
	      my ($e, $uplist)=@_;
	      $e->body_update (sub {
				   cons (uplist_show ($uplist), $_[0])
			       })
	  },
	  sub {
	      my ($v, $uplist)=@_;
	      uplist_show ($uplist) . ($v//"-") . "."
	  })->string }
  '<p>[][p]foo.<b>[p][b|p]bar.[b|p]-.[b|p]5.[b|p]6.[b|p]7.[b|p]8.</b></p>';

TEST { pxml_deferred_map
	 (t_data,
	  sub {
	      my ($e, $uplist, $inferior_map)=@_;
	      $e->body_update
		(sub {
		     my ($body)=@_;
		     cons (uplist_show ($uplist),
			   $e->name eq "b" ? do {
			       my $s= stream_mixed_flatten $body;
			       cons( &$inferior_map (car $s),
				     cdr $s )
			   }
			   : &$inferior_map ($body))
		 });
	  },
	  sub {
	      my ($v, $uplist)=@_;
	      uplist_show ($uplist) . ($v//"-") . "."
	  })->string }
  '<p>[][p]foo.<b>[p][b|p]bar.5678</b></p>';



sub pxml_map_elements ($$) {
    my ($v, $name_to_mapper)= @_;
    pxml_eager_map ($v,
		    sub {
			my ($e, $uplist)=@_;
			if (my ($mapper)= hash_perhaps_ref $name_to_mapper, $e->name) {
			    &$mapper ($e, $uplist)
			} else {
			    $e
			}
		    },
		    undef);
}



1
