#
# Copyright (c) 2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Either - keep two kinds of values in one kind of place

=head1 SYNOPSIS

    use FP::Either;
    my $a = Left 1;
    my $b = Right 1;
    ok is_Left $a;
    ok !is_Right $a;
    ok is_Right $b;
    ok $a->isa("FP::_::Either");
    ok $a->isa("FP::Either::Left");
    is $a->value, 1;
    is $b->value, 1;

    use FP::List;
    use FP::Equal;
    use FP::Either ":all";
    my $l = list Left(9), Left(-8), Right(5);
    ok equal rights($l), list 5;
    ok equal lefts($l), list 9, -8;

=head1 DESCRIPTION

These are used to mark (wrap) two different kinds of data for proper
distinction in a place that should hold either.

`Right` is typically used for the 'right' way, or successful path, or
similar. `Left` would be for the other case, for example to indicate a
failure, or whatever suits the situation at hands.

The naming used here (`Either` with `Left` and `Right` members) is the
one for the data types that the Haskell language uses for error
handling. Rust calls the corresponding types `Result`, with `Err` and
`Ok` members. But given that, especially in Perl, there's less use of
such a module for error handling, but more for other purposes, the
Haskell naming seems like a better match.

=head1 SEE ALSO

L<FP::Failure> (which only wraps the error case).

Implements: L<FP::Abstract::Pure>, L<FP::Struct::Show>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Either;
use strict;
use utf8;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(Left Right is_Left is_Right);
our @EXPORT_OK   = qw(lefts rights);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Carp;
use FP::Predicates qw(instance_of);

package FP::_::Either {
    use FP::Struct ["value"] =>
        ("FP::Abstract::Pure", "FP::Struct::Show", "FP::Struct::Equal");
    _END_
}

package FP::Either::Left {
    use FP::Struct [] => "FP::_::Either";
    _END_
}
FP::Either::Left::constructors->import;

*is_Left = instance_of "FP::Either::Left";

package FP::Either::Right {
    use FP::Struct [] => "FP::_::Either";
    _END_
}
FP::Either::Right::constructors->import;

*is_Right = instance_of "FP::Either::Right";

sub make_lefts_rights {
    my ($is) = @_;
    sub {
        @_ == 1 or fp_croak_arity 1;

        # XX could use filter_map as optimization here, too! Even
        # better a map_filter.
        # XX evil to use the value method directly? This saves one
        # additional sub call.
        $_[0]->filter($is)->map(\&FP::_::Either::value)
    }
}

*lefts  = make_lefts_rights \&is_Left;
*rights = make_lefts_rights \&is_Right;

1
