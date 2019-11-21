#
# Copyright (c) 2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::MutableArray

=head1 SYNOPSIS

 use FP::MutableArray;
 use FP::Div 'inc';

 my $a= mutablearray(1,4,5)->map(*inc);
 is $a->sum, 13;
 $a->[0]++;
 is $a->sum, 14;

 # They can be turned into immutable ones:
 my $b= $a->pure;
 like( (eval { $b->[0]++; 1 } || $@), qr/XXX Hello?/);
  # XXX sigh, expecting 'Modification of a read-only value attempted', but
  # Test::More never fails here ???

 # Although this really consumes the original array, which is now
 # immutable, too:
 like( (eval { $a->[0]++; 1 } || $@), qr/WHATXXX/);

 is $a->sum, 14;

=head1 DESCRIPTION

Native Perl arrays but blessed so that they can follow the sequences
protocol.

=head1 SEE ALSO

Implements: L<FP::Abstract::Sequence>.

L<FP::PureArray>, L<FP::Array>

=head1 NOTE

This is alpha software! Read the package README.

=cut


package FP::MutableArray;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(is_mutablearray mutablearray array_to_mutablearray);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';


sub is_mutablearray ($) {
    length ref ($_[0]) and UNIVERSAL::isa($_[0], "FP::_::MutableArray")
}

sub mutablearray {
    FP::_::MutableArray->new_from_array ([@_])
}

sub array_to_purearray ($) {
    FP::_::MutableArray->new_from_array ($_[0])
}


package FP::_::MutableArray {
    use base qw(FP::Array::Mixin);
    use FP::Interfaces;
    use Carp;
    use Chj::NamespaceCleanAbove;

    sub new_from_array {
        @_==2 or die "wrong number of arguments";
        my ($class, $a)=@_;
        bless $a, $class
    }

    sub constructor_name {
        "mutablearray"
    }
 
    sub pure {
        @_==1 or die "wrong number of arguments";
        # same as `array_to_purearray`
        require FP::PureArray; # cost?
        FP::_::PureArray->new_from_array($_[0])
    }

    our $unsafe_mutable_warned= 0;
    sub unsafe_mutable {
        @_==1 or die "wrong number of arguments";
        my $a=shift;
        carp "is already mutable" unless $unsafe_mutable_warned++;
        $a
    }

    _END_; # Chj::NamespaceCleanAbove

    FP::Interfaces::implemented qw(
        FP::Abstract::Sequence
        FP::Abstract::Equal
        FP::Abstract::Show);
}

1
