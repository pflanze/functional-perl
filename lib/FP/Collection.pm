#
# Copyright (c) 2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Collection

=head1 SYNOPSIS

    use FP::Equal qw(equal is_equal);
    use FP::Collection;
    my $c= Collection 10, 12, 9, 13;
    ok $c->contains(12);
    ok not $c->contains(11);
    # my $c2 = $c->add(11); TODO
    # ok $c2->contains(11);
    # ok not $c->contains(11);

    # always sorted? Oh, and by string?
    is_equal [$c->values], [10, 12, 13, 9];

    is_equal Collection(10, 13), Collection(13, 10);
    ok not equal Collection(10, 13), Collection(13, 10, 11);
    ok not equal Collection(10, 13), Collection(13, 10, 11);

=head1 DESCRIPTION

Unlike L<FP::HashSet> these are objects, but there's currently not
much more to it and those two should either be merged into 1 module
(that can handle both blessed and unblessed ones?), or FP::Collection
should be the pure variant. Thus this is very much unfinished.

=head1 SEE ALSO

Implements: L<FP::Abstract::Show>, L<FP::Abstract::Equal>. (TODO: L<FP::Abstract::Sequence>?)

Members have to implement (or be covered by L<FP::Id::id>): L<FP::Abstract::Id>.

Other: L<FP::HashSet>.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Collection;
use strict;
use utf8;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(Collection);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Id;

sub Collection {
    my %c;
    for (@_) {
        my $id = id $_;

        # ^ optimize via inlining? forever.
        die "Collection: duplicate elements with id '$id': $c{$id}, $_"
            if exists $c{$id};

        # ^ consciously use stringification so that pointers can be
        #   seen?
        $c{$id} = $_;
    }
    bless \%c, "FP::_::Collection"
}

package FP::_::Collection {
    use FP::Carp;
    use FP::Id;
    use FP::Equal;
    use Chj::NamespaceCleanAbove;

    sub contains {
        @_ == 2 or fp_croak_arity 2;
        exists $_[0]->{ id $_[1] }
    }

    sub values {
        @_ == 1 or fp_croak_arity 1;
        my ($v) = @_;
        map { $v->{$_} } sort keys %$v
    }

    # sub add, or wait till can do this efficiently ?

    sub FP_Equal_equal {
        my ($a, $b) = @_;
        %$a == %$b and do {
            for (keys %$a) {
                exists $b->{$_} and equal($a->{$_}, $b->{$_}) or return '';
            }
            1
        }
    }

    sub FP_Show_show {
        my ($s, $show) = @_;
        "Collection("
            . join(", ", map { $show->($s->{$_}) } sort keys %$s) . ")"
    }

    use FP::Interfaces;
    FP::Interfaces::implemented qw(FP::Abstract::Show FP::Abstract::Equal);
}

1
