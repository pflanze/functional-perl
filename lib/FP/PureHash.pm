#
# Copyright (c) 2019-2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::PureHash

=head1 SYNOPSIS

    use FP::PureHash;
    use FP::Show; use FP::Predicates;

    my $h = purehash hi => 123, there => "World";
    my $h2 = $h->set("hi", "again");
    is $h->ref("there"), "World";
    is $$h{there}, "World";
    is show($h), "purehash('hi' => 123, 'there' => 'World')";
    is show($h2), "purehash('hi' => 'again', 'there' => 'World')";
    is is_pure($h2), 1;

    like( (eval { purehash hi => 1, hi => 1, there => 2 } || $@),
          qr/^duplicate key: 'hi' at/ );
    like( (eval { $$h{there_} || 1} || $@),
          # the detailed exception message may change!
          qr/^Attempt to access disallowed key 'there_' in a restricted hash/ );

=head1 DESCRIPTION

Hash tables, currently based simply on Perl's internal hashes. They
are immutable, and restricted which means that accessing non-existing
keys yields an exception.


=head1 TODO

- performant functional updates (currently the `set` method simply
  copies the whole table)

- more methods, move/adapt set functionality from FP::Hash and
  FP::HashSet

- a maybe_ref that returns FP::Failure or FP::Maybe ?

- non-string keys?

=head1 SEE ALSO

Implements: L<FP::Abstract::Pure>, L<FP::Abstract::Map>,
L<FP::Abstract::Equal>, L<FP::Abstract::Show>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::PureHash;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(purehash);
our @EXPORT_OK   = qw(hash_clone_to_purehash hash_to_purehash);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Docstring;
use FP::Show;
use Scalar::Util qw(blessed);
use FP::Carp;

our $immutable = 1;

sub purehash {
    __
        'convert key/value pairs to an immutable hash; re-use of keys is an error';
    die "uneven number of arguments" if @_ & 1;
    my %out;
    for (my $i = 0; $i < @_; $i += 2) {
        my $k = $_[$i];
        if (exists $out{$k}) {
            die "duplicate key: " . show($k);
        }
        $out{$k} = $_[$i + 1];
        Internals::SvREADONLY $out{$k}, 1 if $FP::PureHash::immutable;
    }
    my $res = bless \%out, "FP::_::PureHash";
    Internals::SvREADONLY %out, 1 if $FP::PureHash::immutable;

    # XX ^ this also changes the behaviour accessing a non-existing key, yeah;
    # why not just   overload? oh  that was said to be slow or was it Tie  ?
    $res
}

sub hash_clone_to_purehash {
    @_ == 1 or fp_croak_arity 1;
    FP::_::PureHash->new_from_hash({ %{ $_[0] } })
}

sub hash_to_purehash {
    @_ == 1 or fp_croak_arity 1;
    FP::_::PureHash->new_from_hash($_[0])
}

sub is_purehash {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
    my $r = blessed($v) // return;
    $v->isa("FP::_::PureHash")
}

package FP::Hash::Mixin {
    use FP::Equal 'equal';
    use Chj::NamespaceCleanAbove;

    sub FP_Show_show {
        my ($s, $show) = @_;
        $s->constructor_name . "("
            . join(", ",
            map { &$show($_) . " => " . &$show($$s{$_}) } sort keys %$s)
            . ")"
    }

    sub FP_Equal_equal {
        my ($a, $b) = @_;
        keys(%$a) == keys(%$b) and do {
            for my $key (keys %$a) {
                exists $$b{$key}            or return 0;
                equal($$a{$key}, $$b{$key}) or return 0;
            }
            1
        }
    }

    _END_
}

package FP::PureHash::autobox {
    our $AUTOLOAD;

    sub AUTOLOAD {
        my $methodname = $AUTOLOAD;
        $methodname =~ s/.*:://;
        my $v = FP::_::PureHash->new_from_hash($_[0]);
        if (my $m = $v->can($methodname)) {
            goto $m
        } else {
            die "no method '$methodname' found for object: $v";
        }
    }
}

package FP::_::PureHash {
    use base "FP::Hash::Mixin";
    use FP::Interfaces;
    use FP::Carp;
    use Chj::NamespaceCleanAbove;

    sub new_from_hash {
        @_ == 2 or fp_croak_arity 2;
        my ($class, $out) = @_;
        if ($FP::PureHash::immutable) {
            for my $k (keys %$out) {
                Internals::SvREADONLY $out->{$k}, 1
            }
        }
        my $res = bless $out, "FP::_::PureHash";
        Internals::SvREADONLY %$out, 1 if $FP::PureHash::immutable;
        $res
    }

    sub constructor_name {"purehash"}

    # XX  why not get, again? set and get? If ref, then what for set?
    sub ref {
        @_ == 2 or fp_croak_arity 2;
        my ($s, $key) = @_;
        $$s{$key}
    }

    sub perhaps_ref {
        @_ == 2 or fp_croak_arity 2;
        my ($s, $key) = @_;
        exists $$s{$key} ? $$s{$key} : ()
    }

    sub set {
        @_ == 3 or fp_croak_arity 3;
        my ($s, $key, $val) = @_;

        # XX the inefficient approach...  to be replaced with new impl.
        my %out = %$s;
        $out{$key} = $val;
        if ($FP::PureHash::immutable) {
            for my $k (keys %out) {
                Internals::SvREADONLY $out{$k}, 1
            }
        }
        my $res = bless \%out, "FP::_::PureHash";
        Internals::SvREADONLY %out, 1 if $FP::PureHash::immutable;
        $res
    }

    FP::Interfaces::implemented qw(
        FP::Abstract::Pure
        FP::Abstract::Map
        FP::Abstract::Equal
        FP::Abstract::Show);

    _END_
}

1
