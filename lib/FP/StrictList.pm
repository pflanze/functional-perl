#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

FP::StrictList - an FP::List that enforces list semantics

=head1 SYNOPSIS

 use FP::StrictList;
 my $l= strictlist (4,5)->map(*inc);
 is_strictlist $l # true, O(1)

 use FP::Equal 'equal';
 equal strictnull->cons(1), cons (1, strictnull)
   # true
 use FP::List 'null';
 equal strictnull->cons(1), cons (1, null)
   # false: `cons` from `FP::List` and `FP::StrictList` are the same
   # function but it takes the type of their second argument into
   # consideration.

=head1 DESCRIPTION

FP::List does not (currently) enforce its pairs to only contain pairs
or null in their rest (cdr) position. Which means that they may end in
something else than a null (and operations encountering these will die
with "improper list"). FP::StrictList does, which means that
`is_strictlist` only needs to check the head pair to know whether it's
a proper list.

Also, they maintain the list length within each pair, thus `length`
has O(1) complexity instead of O(n) like the `length` from FP::List.

Both of these features dictate that the list can't be lazy (since (in
a dynamically typed language) it's impossible to know the type that a
promise will give without evaluating it, or worse, know the length of
the unevaluated tail).

Keep in mind that destruction of strict lists requires space on the C
stack proportional to their length. You will want to increase the C
stack size when handling big strict lists, lest your program will
segfault.

Currently FP::StrictList mostly only offers method based
functionality. It inherits all the methods from FP::List, but only
re-exports those basic functions that are basic and don't have "list_"
prefixes, and only on demand. The only special functions (and the only
ones exported by default) are `strictnull` and `is_strictlist`. Since
StrictList enforcess list structure, methods are guaranteed to always
work on the rest field of a pair. Hence, the suggestion is to simply
use method calls and `the_method` from `FP::Ops` to pass methods as
first class functions.

=head SEE ALSO

L<FP::List>, L<FP::Ops>

=cut


package FP::StrictList;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(strictnull is_strictlist);
@EXPORT_OK=qw(
		 cons
		 first second rest car cdr car_and_cdr first_and_rest
	    );
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


TEST {
    strictlist (4,5)->map (sub{$_[0]+1})
}
  cons (5, cons (6, strictnull));


sub is_strictlist ($) {
    my ($v)=@_;
    if (length (my $r= ref $v)) {
	UNIVERSAL::isa($v, "FP::StrictList::Pair")
	    or
	UNIVERSAL::isa($v, "FP::StrictList::Null")
    } else {
	''
    }
}

TEST { [map { is_strictlist $_ } 
	null, strictnull, cons (1,null), cons (1,strictnull)] }
  ['', 1, '', 1];

TEST {
    is_strictlist (strictlist (4,5)->map (sub{$_[0]+1}))
}
  1;

TEST {
    is_strictlist (list (4,5)->map (sub{$_[0]+1}))
}
  '';

use FP::Equal 'equal';

TEST {
    equal strictnull->cons(1), cons (1, strictnull)
} 1;

TEST {
    equal strictnull->cons(1), cons (1, null)
} '';


1
