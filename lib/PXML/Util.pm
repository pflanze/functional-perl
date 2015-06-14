#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

PXML::Util

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package PXML::Util;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(pxml_eager_map);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use Chj::TEST;
use FP::List;
use FP::Stream ":all";

# taking value first, like in OO syntax (saves a `flip` or similar
# call, too)

sub pxml_eager_map ($$;$$) {
    # The functions receive (value, up-list), where up-list is a
    # linked list to the parents
    my ($v, $elementfn, $maybe_otherfn, $maybe_uplist)= @_;
    my $uplist= $maybe_uplist // null;
    my $uplist2= cons $v, $uplist;
    my $rec_with_uplist= sub {
	my ($uplist_)=@_;
	sub {
	    pxml_eager_map ($_[0],
			    $elementfn,
			    $maybe_otherfn,
			    $uplist_)
	}
    };
    if (my $r= ref $v) {
	if (UNIVERSAL::isa ($v, "PXML")) {
	    # XX TCO?
	    &$elementfn ($v->body_map(&$rec_with_uplist ($uplist2)),
			 $uplist);
	} else {
	    stream_map (&$rec_with_uplist ($uplist),
			stream_mixed_flatten ($v))
	}
    } else {
	$maybe_otherfn ? &$maybe_otherfn ($v) : $v
    }
}

sub t_data {
    require PXML::XHTML;
    PXML::XHTML::P("foo", PXML::XHTML::B("bar", undef, stream_iota (5)->take(4)))
}

TEST { t_data->string }
  '<p>foo<b>bar5678</b></p>';

TEST { pxml_eager_map
	 (t_data,
	  sub { $_[0]->name_update(sub {$_[0]."A"})},
	  sub { ($_[0]//"-")."."} )->string }
  '<pA>foo.<bA>bar.-.5.6.7.8.</bA></pA>';

1
