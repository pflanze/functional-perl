#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::PureArray

=head1 SYNOPSIS

    use FP::PureArray;
    use FP::Div 'inc';

    my $a= purearray(1,4,5)->map(*inc);
    is $a->sum, 13;

    # can't mutate it:
    like( (eval { $a->[0]++; 1 } || $@),
          qr/^Modification of a read-only value attempted/);
    like( (eval { push @$a, 123; 1 } || $@),
          qr/^Modification of a read-only value attempted/);

    is $a->sum, 13;

    my $b= $a->unsafe_mutable; # efficient but dangerous!
    $$b[0]++;
    is $a->sum, 14; # said it was dangerous!
    is ref($a), 'FP::_::MutableArray';
    # see FP::MutableArray

    is( FP::_::PureArray->null == FP::_::PureArray->null, 1);

=head1 DESCRIPTION

Perl arrays blessed into the `FP::PureArray` package, inheriting from
`FP::Abstract::Pure`, and coming with the functions from `FP::Array` as methods.

If you hand someone an FP::PureArray you guarantee that you won't
mutate it. This might be enforced in the future by making them
immutable (todo).

=head1 PURITY

`PureArray`s are created to be immutable by default, which enforces
the functional purity of the API. This can be disabled by setting
`$FP::PureArray::immutable` to false when creating them. Only ever use
this during development, if at all. If you need to have efficient
updates, use another data structure (L<FP::List> suits many cases, or
the to-be written L<FP::Vec>, although at that point updates directly
on PureArray may be implemented efficiently, too). Or if you're sure
making a PureArray mutable again is safe, you can call the
`unsafe_mutable` method. Should lexical analysis get implemented in
Perl at some point, a method `mutable` could be offered that safely
(by way of checking via the reference count that there are no other
users) turns a PureArray back into a mutable array.

PureArray implements `FP::Abstract::Pure` (`is_pure` from
`FP::Predicates` returns true even if instances were made mutable via
setting `$FP::PureArray::immutable`). Values returned from
`unsafe_mutable` are in a different class which does *not* implement
`FP::Abstract::Pure`.

=head1 TODO

Create alternative implementation that is efficient for updates on big
arrays (perhaps to be called FP::Vec, but to be interoperable).

=head1 SEE ALSO

Implements: L<FP::Abstract::Pure>, L<FP::Abstract::Sequence>,
L<FP::Abstract::Equal>, L<FP::Abstract::Show>

L<FP::MutableArray>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FP::PureArray;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(is_purearray purearray);
@EXPORT_OK=qw(array_clone_to_purearray array_to_purearray);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use FP::Interfaces;
use Carp;


our $immutable= 1; # whether new instances are to be immutable


sub is_purearray ($) {
    length ref ($_[0]) and UNIVERSAL::isa($_[0], "FP::_::PureArray")
}

sub purearray {
    FP::_::PureArray->new_from_array ([@_])
}

sub array_clone_to_purearray ($) {
    FP::_::PureArray->new_from_array ([@{$_[0]}])
}

sub array_to_purearray ($) {
    FP::_::PureArray->new_from_array ($_[0])
}


package FP::PureArray::autobox {
    our $AUTOLOAD;
    sub AUTOLOAD {
        my $methodname= $AUTOLOAD;
        $methodname =~ s/.*:://;
        my $v= FP::_::PureArray->new_from_array($_[0]);
        if (my $m= UNIVERSAL::can($v, $methodname)) {
            goto $m
        } else {
            die "no method '$methodname' found for object: $v";
        }
    }
}

package FP::_::PureArray {
    use base qw(FP::Array::Mixin);
    use FP::Interfaces;
    use Carp;
    use Chj::NamespaceCleanAbove;

    sub new_from_array {
        @_==2 or die "wrong number of arguments";
        my ($class, $a)=@_;
        bless $a, $class;
        if ($FP::PureArray::immutable) {
            Internals::SvREADONLY $_, 1
                for @$a;
            Internals::SvREADONLY @$a, 1;
        }
        $a
    }

    # emptyness constructor that works for subclassing (using singletons
    # for performance (perhaps))
    my %null;
    sub null {
        my $proto=shift;
        my $class= ref($proto) || $proto;
        $null{$class} ||= $class->new_from_array([]) 
    }

    sub constructor_name {
        "purearray"
    }


    our $pure_warned= 0;
    sub pure {
        @_==1 or die "wrong number of arguments";
        my $a=shift;
        carp "is already pure" unless $pure_warned++;
        $a
    }

    sub unsafe_mutable {
        @_==1 or die "wrong number of arguments";
        my $a=shift;
        Internals::SvREADONLY $_, 0
            for @$a;
        Internals::SvREADONLY @$a, 0;
        require FP::MutableArray; # cost?
        bless $a, "FP::_::MutableArray" 
    }

    _END_; # Chj::NamespaceCleanAbove

    FP::Interfaces::implemented qw(
        FP::Abstract::Pure
        FP::Abstract::Sequence
        FP::Abstract::Equal
        FP::Abstract::Show);
}

1
