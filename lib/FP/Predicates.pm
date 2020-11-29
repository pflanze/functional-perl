#
# Copyright (c) 2014-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Predicates

=head1 SYNOPSIS

    use FP::Predicates;

    is is_string("Hi"), 1;
    is is_string(["Hi"]), 0;
    use FP::List; use FP::Equal 'is_equal';
    is_equal list(1, 2, 3, 0, -1, "hi", [1])->map(*is_natural0),
             list(1, 1, 1, 1, 0, 0, 0);

    package Foo {
        use FP::Predicates;

        *is_age = both *is_natural0, sub { $_[0] < 130 };
        # ^ if you do not want this to show up as a method,
        #   wrap it in BEGIN { } to get deleted in FP::Struct's
        #   namespace cleaning step; or assign to a scalar instead (my
        #   $is_age), of course; or use an inline expression (second
        #   line below)

        use FP::Struct [[*is_string, "name"], [*is_age, "age"]];

        # use FP::Struct [[*is_string, "name"],
        #                 [both (*is_natural0, less_than 130), "age"]];

        _END_
    }

    is (Foo->new("Moo", 13)->age, 13);


    # Experimental:
    {
        use FP::Failure '*use_failure';
        local $use_failure = 1;

        my $isp = is_pure_class("FP::Array");
        is $isp ? "yes" : "no", "no";
        is $isp->message,
           "failure: is_pure_class: 'FP::Array'\n";
        is is_pure_class("FP:: Array")->message,
           "failure: is_pure_class\n".
           "  because:\n".
           "  failure: is_class_name: 'FP:: Array'\n";
    }

=head1 DESCRIPTION

Useful as predicates for FP::Struct field definitions.

These are simple functions expecting one value and returning a
boolean. They are composable with `maybe`, `complement`, `either`,
`all_of`/`both`.

This is a functional approach to achieve the same aim as
`Moose::Util::TypeConstraints`, which basically uses a syntactical
sublanguage instead (implemented as a mix of functions and string
interpretation). It was written because it's way simpler. The drawback
is that (currently) there's no way to get a nice message string from
them to say why a match fails. Perhaps it would be possible to do so
using more introspection? (That would be nice because message
generation would be fully automatic and hence consistent.) Or,
alternatively, modifying the functions to compose messages themselves
when they fail (still mostly automatic), e.g. using message objects
that are false.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Predicates;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT = qw(
    is_pure
    is_pure_object
    is_pure_class
    is_string
    is_nonnumeric_string
    is_nonnullstring
    is_natural0
    is_natural
    is_even is_odd
    is_boolean01
    is_booleanyesno
    is_boolean
    is_hash
    is_array
    is_procedure
    is_class_name
    instance_of
    is_instance_of
    is_subclass_of

    is_filehandle

    is_filename
    is_sequence
    is_proper_sequence
    is_seq

    less_than
    greater_than
    less_equal
    greater_equal
    is_zero

    maybe
    is_defined
    is_true
    true
    is_false
    false
    complement
    either
    all_of both
);
our @EXPORT_OK = qw(
    is_coderef
);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Chj::TEST;
use FP::Abstract::Pure;
use Chj::BuiltinTypePredicates 'is_filehandle';

# ^ should probably move more lowlevel predicates there
use Scalar::Util qw(looks_like_number blessed);

# Only use `FP::Failure` features if $FP::Failure::use_failure is
# true--which means that FP::Failure should be loaded, no need to
# require it, OK? (Not strictly true; some module could set
# $FP::Failure::use_failure withouth loading the latter; but really
# that should be considered a bug and is why I do like/prefer the
# approach of importing *use_failure, then FP::Failure is loaded
# implicitly.)

sub failwith {
    my ($parents, $msg, @vals) = @_;
    $FP::Failure::use_failure
        ? FP::Failure::failure(FP::Failure::message($msg, @vals), $parents)
        : 0
}

sub fail {
    my ($msg, @vals) = @_;
    $FP::Failure::use_failure
        ? FP::Failure::failure(FP::Failure::message($msg, @vals))
        : 0
}

# XX check for read-only flags?

# is_pure returns true for non-references, going with the assumption
# that the caller created a copy of those anyway, in which case there
# is no reason for fear from mutations from scopes before it got
# control of the value:
sub is_pure {
    my ($v) = @_;
    blessed($v) // return ((length ref $v) ? '' : 1);
    $v->isa("FP::Abstract::Pure") or fail "is_pure", $v
}

sub is_pure_object {
    my ($v) = @_;
    blessed($v) // return;
    $v->isa("FP::Abstract::Pure") or fail "is_pure_object", $v
}

sub is_pure_class {
    my $r = is_class_name($_[0]);
    $r or return failwith [$r], "is_pure_class";
    $_[0]->isa("FP::Abstract::Pure") or fail "is_pure_class", $_[0]
}

sub is_string {
    my ($v) = @_;
    (defined $v and not ref $v)    # relax?
        or fail "is_string", $v
}

sub is_nonnumeric_string {
    my ($v) = @_;
    (
        defined $v and not ref $v    # relax?
            and not looks_like_number($v)
        )
        or fail "is_string", $v
}

sub is_nonnullstring {
    my ($v) = @_;
    (
        defined $v and not ref $v    # relax?
            and length $v
        )
        or fail "is_nonnullstring", $v
}

sub is_natural0 {
    my ($v) = @_;
    (
        defined $v and not ref $v    # relax?
            and $v =~ /^\d+\z/
        )
        or fail "is_natural0", $v
}

sub is_natural {
    my ($v) = @_;
    (
        defined $v and not ref $v       # relax?
            and $v =~ /^\d+\z/ and $v
        )
        or fail "is_natural", $v
}

# XX careful these do not check for number types first

sub is_even {
    ($_[0] & 1) == 0 or fail "is_even", $_[0]
}

sub is_odd {
    ($_[0] & 1) or fail "is_odd", $_[0]
}

TEST {
    [map { is_even $_ } -3 .. 3]
}
[0, 1, 0, 1, 0, 1, 0];
TEST {
    [map { is_odd $_ } -3 .. 3]
}
[1, 0, 1, 0, 1, 0, 1];
TEST {
    [map { is_even $_ } 3, 3.1, 4, 4.1, -4.1]
}

# XX what should it give?
[0, 0, 1, 1, 1];

# no `is_` prefix as those are not the final predicates (they are
# curried forms of < and > etc.):

# names? (number versus string comparison) (wish Perl hat generics
# for those instead..)

sub less_than {
    my ($x) = @_;

    sub {
        $_[0] < $x or fail "less_than", $x, $_[0]    # last value last, ok?
    }
}

sub greater_than {
    my ($x) = @_;

    sub {
        $_[0] > $x or fail "greater_than", $x, $_[0]    # last value last, ok?
    }
}

sub less_equal {
    my ($x) = @_;

    sub {
        $_[0] <= $x or fail "less_equal", $x, $_[0]     # last value last, ok?
    }
}

sub greater_equal {
    my ($x) = @_;

    sub {
        $_[0] >= $x or fail "greater_equal", $x, $_[0]    # last value last, ok?
    }
}

sub is_zero {
    $_[0] == 0 or fail "is_zero", $_[0]
}

# strictly 0 or 1
sub is_boolean01 {
    (
        not ref($_[0])                                    # relax?
            and $_[0] =~ /^[01]\z/
        )
        or fail "is_boolean01", $_[0]
}

sub is_booleanyesno {
    my ($v) = @_;
    (not ref $v and $v eq "yes" or $v eq "no") or fail "is_booleanyesno", $v
}

# undef, 0, "", or 1
sub is_boolean {
    (
        not ref($_[0])    # relax?
            and (!$_[0] or $_[0] eq "1")
        )
        or fail "is_boolean", $_[0]
}

sub is_hash {
    (defined $_[0] and ref($_[0]) eq "HASH") or fail "is_hash", $_[0]
}

sub is_array {
    (defined $_[0] and ref($_[0]) eq "ARRAY") or fail "is_array", $_[0]
}

# Usually you should prefer `is_procedure` (see below) over this, as
# we like to pass globs as subroutine place holders, too.

sub is_coderef {
    (defined $_[0] and ref($_[0]) eq "CODE") or fail "is_coderef", $_[0]
}

# Should this be called `is_subroutine` or `is_sub` instead, to cater
# for the traditional naming in Perl? But then Perl itself is
# inconsistent, too, calling those code refs, which matches the
# is_coderef naming above.

sub is_procedure {
    (
        defined $_[0]
            and (ref($_[0]) eq "CODE"
            or (ref \($_[0]) eq "GLOB" ? *{ $_[0] }{CODE} ? 1 : '' : ''))
        )

        # XX: also check for objects that overload '&'?
        or fail "is_procedure", $_[0]
    }

    TEST { is_procedure [] } 0;
TEST { is_procedure \&is_procedure } 1;
TEST { is_procedure *is_procedure } 1;
TEST { is_procedure *fifu } 0;

my $classpart_re = qr/\w+/;

sub is_class_name {
    my ($v) = @_;
    !length ref($v) and $v =~ /^(?:${classpart_re}::)*$classpart_re\z/
        or fail "is_class_name", $v
}

sub instance_of {
    my ($class) = @_;
    is_class_name $class or die "need class name string, got: $class";

    sub {
        ((defined blessed $_[0]) ? $_[0]->isa($class) : '')
            or fail "instance_of", $class, $_[0]
    }
}

sub is_instance_of {
    my ($v, $class) = @_;

    # is_class_name $class or die "need class name string, got: $class";
    ((defined blessed $v) ? $v->isa($class) : '')
        or fail "is_instance_of", $v, $class
}

sub is_subclass_of {
    my ($v, $class) = @_;

    # is_class_name $class or die "need class name string, got: $class";
    (!length ref $v and $v->isa($class)) or fail "is_subclass_of", $v, $class
}

TEST { my $v = "IO"; is_instance_of $v, "IO" } 0;
TEST { my $v = bless [], "IO"; is_instance_of $v, "IO" } 1;
TEST { my $v = "IO"; is_subclass_of $v, "IO" } 1;
TEST {
    require Chj::IO::File;
    is_subclass_of "Chj::IO::File", "IO"
}
1;

# is_filename in Chj::BuiltinTypePredicates

TEST {
    [
        map { is_filehandle $_ } "STDOUT",
        undef, *STDOUT,
        *STDOUT{IO},
        \*STDOUT,
        *SMK69GXDB,
        *SMK69GXDB{IO},
        \*SMK69GXDB,
        bless(\*WOFWEOXVV, "ReallyNotIO"),
        do {
            open my $in, '<', __FILE__ or die $!;

            #warn "HM".<$in>;  # works
            bless $in, "MightActullyBeIO"
        }
    ]
}
['', '', '', 1, 1, '', '', '', '', 1];

# should probably be in a filesystem lib instead?
sub is_filename {
    my ($v) = @_;
    (is_nonnullstring($v) and !($v =~ m|/|) and !($v eq ".") and !($v eq ".."))
        or fail "is_filename", $v
}

# can't be in `FP::Abstract::Sequence` since that package is for OO, well, what
# to do about it?
use FP::Lazy;    # sigh dependency, too.
use FP::Carp;

sub is_sequence {
    my $v = force $_[0];
    blessed($v) // return;
    $v->isa("FP::Abstract::Sequence") or fail "is_sequence", $v
}

sub is_proper_sequence {
    my $v = force $_[0];
    blessed($v) // return;
    ($v->isa("FP::Abstract::Sequence") and $v->is_proper_sequence)
        or fail "is_sequence", $v
}

# Like is_sequence but only returns true when the sequence isn't empty
# (similar to Clojure's `(seq? (seq v))`)
sub is_seq {
    my $v = force $_[0];
    blessed($v) // return;
    ($v->isa("FP::Abstract::Sequence") && (not $v->is_null))
        or fail "is_sequence", $v
}

sub maybe {
    @_ == 1 or fp_croak_nargs 1;
    my ($pred) = @_;

    sub {
        my ($v) = @_;
        defined $v
            ? do {
            my $b = &$pred($v);
            $b or failwith [$b], "maybe"
            }
            : 1
    }
}

# (this would also be a candidate for FP::Ops)
sub is_defined {
    defined $_[0] or fail "is_defined", $_[0]
}

sub is_true {
    $_[0] or fail "is_true", $_[0]
}

# (this would also be a candidate as 'not' with a different name for
# FP::Ops)
sub is_false {
    @_ == 1 or fp_croak_nargs 1;
    !$_[0] or fail "is_false", $_[0]
}

sub true {
    1
}

sub false {
    0
}

sub complement {
    @_ == 1 or fp_croak_nargs 1;
    my ($f) = @_;
    sub {
        my $r = &$f(@_);
        !$r

            # XX: in a perfect world we would have information about
            # why $f *succeeded* here. Sigh. We don't. TODO?
            or failwith [fail "not"], "complement"
    }
}

TEST {
    my $t = complement(\&is_natural);
    [map { &$t($_) } (-1, 0, 1, 2, "foo")]
}
[1, 1, 0, 0, 1];

sub either {
    my (@fn) = @_;
    sub {
        # Meh, code it up all twice. Macros anyone?
        if ($FP::Failure::use_failure) {
            my @failures;
            for my $fn (@fn) {
                my $r = &$fn;
                return $r if $r;
                push @failures, $r
            }
            failwith \@failures, "either"
        } else {
            for my $fn (@fn) {
                my $r = &$fn;
                return $r if $r;
            }
            0
        }
    }
}

TEST {
    my $t = either \&is_natural, \&is_boolean;
    [map { &$t($_) } (-1, 0, 1, 2, "foo")]
}
[0, 1, 1, 2, 0];

sub all_of {
    my (@fn) = @_;
    sub {
        for my $fn (@fn) {
            my $r = &$fn;
            return failwith [$r], "all_of" unless $r;
        }
        1
    }
}

sub both {
    @_ == 2 or fp_croak_nargs 2;
    all_of(@_)
}

1
