#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

FP::StrictList - an FP::List enforcing list semantics

=head1 SYNOPSIS

=head1 DESCRIPTION

FP::List does not (currently) enforce its pairs to only contain pairs
or null in their rest (cdr) position. Which means that they may end in
something else than a null (and operations encountering these will die
with "improper list"). FP::StrictList does, which means that
`is_strictlist` only needs to check the head pair to know whether it's
a proper list. Also, they maintain the list length, so `length` is
O(1) instead of O(n) like with FP::List. Both of these features
dictate that the list can't be lazy (since (in a dynamically typed
language) it's impossible to know the type that a promise will give
without evaluating it). Keep in mind that destruction of strict lists
requires space on the C stack proportional to their length. You will
want to increase the C stack size when handling big strict lists, lest
your program will segfault.

=cut


package FP::StrictList;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use FP::List;
use Chj::TEST;

{
    package FP::StrictList::Null;
    our @ISA= "FP::List::Null";

    sub pair_namespace { "FP::StrictList::Pair" }

    sub cons {
	@_==2 or die "wrong number of arguments";
	my $s=shift;
	# different than FP::List::Null::cons in that it needs to set
	# the length field, too:
	bless [$_[0], $s, 1], $s->pair_namespace
    }

}

{
    package FP::StrictList::Pair;
    our @ISA= "FP::List::Pair";

    # represented as blessed [ v, pair-or-null, length]

    sub cons {
	@_==2 or die "wrong number of arguments";
	my $s=shift;
	bless [$_[0], $s, $$s[2]+1], ref $s
    }

    sub length {
	$_[0][2]
    }
}

# nil
my $null= bless [], "FP::StrictList::Null";

sub strictnull () {
    $null
}

TEST { strictnull->cons(1)->cons(2)->array }
  [2,1];

TEST { strictnull->length }
  0;
TEST { strictnull->cons(8)->length }
  1;
TEST { strictnull->cons(1)->cons(9)->length }
  2;

sub strictlist {
    my $res= strictnull;
    for (my $i= $#_; $i>=0; $i--) {
	$res= $res-> cons ($_[$i]);
    }
    $res
}

sub strictcons ($$) {
    @_==2 or die "wrong number of arguments";
    # use method calls internally anyway, to allow for subclassing,
    # and since the combination of the null case and the length field
    # requires a type dispatch anyway

    $_[1]->cons ($_[0])
}
# XX should change 'cons' in FP::List to this definition and simply
# always reuse that one


TEST {
    strictlist (4,5)->map (sub{$_[0]+1})
}
  strictcons (5, strictcons (6, strictnull));


1
