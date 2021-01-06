#
# Copyright (c) 2015-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Optional - dealing with optional values

=head1 SYNOPSIS

    use FP::Optional qw(perhaps_to_maybe perhaps_to_x perhaps_to_or
                        perhaps_to_exists
                        optionally poptionally);

    sub perhaps_div {
        my ($a, $b) = @_;
        $b == 0 ? () : $a/$b
    }
    if (my ($r) = perhaps_div 10, 2) {
        is $r, 5;
    }
    *maybe_div = perhaps_to_maybe \&perhaps_div;
    is maybe_div(10, 2), 5;
    is maybe_div(10, 0), undef;

    use FP::Div qw(square);
    # short-cutting evaluation for undef:
    *optionally_square = optionally(\&square);
    is optionally_square(2), 4;
    is optionally_square(undef), undef;


=head1 DESCRIPTION

Places holding or code passing optional values do either hold or pass
a 'real' value, or the absence of a value ('nothing').

There are two straight-forward ways to return 'nothing' from a
function: undef and the empty list. The empty list has the advantage
that it is unambiguous, but the disadvantage that the result needs to
be received in list context, which can be more verbose, also, there is
the danger of accidentally interpolate the result into a list of other
values, which will go wrong if the values in the list have positional
meaning.

Example using undef:

=for test ignore
    package Users;
    my %uid_to_username;
    sub maybe_uid_to_username {
        my ($uid) = @_;
        $uid_to_username{$uid}
    }
    package main;
    use Users;
    if (defined (my $user = maybe_uid_to_username (123))) {
        ...
    } else {
        ...
    }
    my @existing_usernames = map {
        my $maybe_username = maybe_uid_to_username $_;
        defined $maybe_uid_to_username ? $maybe_uid_to_username : ()
    } @uids;

    # assume rename_user expects pairs of usernames:
    rename_users (map { maybe_uid_to_username $_ } @uidpairs)

Example using the empty list:

    package Users;
    my %uid_to_username;
    sub perhaps_uid_to_username {
        my ($uid) = @_;
        exists $uid_to_username{$uid} ? $uid_to_username{$uid} : ()
    }
    package main;
    use Users;
    if (my ($user) = perhaps_uid_to_username (123)) {
        ...
    } else {
        ...
    }
    my @existing_usernames = map { perhaps_uid_to_username $_ } @uids;

    # This would be *wrong*:
    # rename_users (map { perhaps_uid_to_username $_ } @uidpairs)

    # Instead this wordy version would need to be used:
    rename_users (map {
        if (my ($name) = perhaps_uid_to_username $_) {
             $name
        } else {
             undef
    } @uidpairs);

An alternative to optional values are exceptions:

    package Users;
    my %uid_to_username;
    sub x_uid_to_username {
        my ($uid) = @_;
        exists $uid_to_username{$uid} ? $uid_to_username{$uid}
           : die "no such user"
    }
    package main;
    use Users;
    my $user = x_uid_to_username (123);
    ...
    my @existing_usernames = map {
        my $name;
        eval { $name = x_uid_to_username $_; 1 } ? $name : ()
    } @uids;

    rename_users (map { x_uid_to_username $_ } @uidpairs);


The functional perl project *always* prefixes function names with
`maybe_` or `perhaps_` if they optionally don't return a value, and
depending on whether they do so by returning undef or the empty
list. The reason is to make the user of the library directly visibly
aware of it, to prevent bugs.

It also prefixes variable names with maybe_ if they are
optionally undef. (If they are introduced in an `if` conditional form,
then no prefixing is done as they will always be set in the scope of
the variable (well, this is not strictly true as in the else branch
they are visible too, but that's more like an accident of the Perl
language, right?))

The functions in this module help convert between functions following
these conventions.

It also offers functions to build chains that propagate failures:

=over 4

=item optionally (\&f [, $pos])

Returns a function that when receiving undef as its first argument, or
$_[$pos] if $pos given, directly returns undef without calling f;
otherwise calls f with the original arguments (with tail-call
optimization).

=item poptionally (\&f)

Returns a function that when not receiving any argument, directly
returns (). Otherwise calls it with the original arguments (tail-call
optimized).

=back

=head1 IDEAS

Implement a binary operator (perhaps named `%%` or `otherwise`), that
evaluates the left-hand side in list context, and returns the
right-hand side if the result is the empty list, or the last element
of the list otherwise.  (Zefram says one could implement such an
operator, using cv_set_call_checker() and generating a custom op based
on OP_DOR.) Example code: `pass($foo->perhaps_name %% $myname)`.

=head1 SEE ALSO

`maybe` in L<FP::Predicates>

Perl 6 error values (which are false in conditional context but carry
an error message)

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Optional;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT = qw();
our @EXPORT_OK
    = qw(perhaps_to_maybe perhaps_to_x perhaps_to_or perhaps_to_exists
    optionally poptionally);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Carp;

# Functions to change the kind of optionals API:

sub perhaps_to_maybe {
    @_ == 1 or fp_croak_arity 1;
    my ($f) = @_;
    sub {
        if (my ($v) = &$f(@_)) {
            $v
        } else {
            undef
        }
    }
}

sub perhaps_to_x {
    @_ == 2 or fp_croak_arity 2;
    my ($f, $exception) = @_;
    sub {
        if (my ($v) = &$f(@_)) {
            $v
        } else {
            die $exception
        }
    }
}

sub perhaps_to_or {
    @_ == 1 or fp_croak_arity 1;
    my ($f) = @_;
    sub {
        @_ == 3 or fp_croak_arity 3;
        my ($t, $k, $other) = @_;
        if (my ($v) = &$f($t, $k)) {
            $v
        } else {
            $other
        }
    }
}

sub perhaps_to_exists {
    @_ == 1 or fp_croak_arity 1;
    my ($f) = @_;
    sub {
        if (my ($_v) = &$f(@_)) {
            1
        } else {
            ''
        }
    }
}

# Functions to help build chains:

# build functions that short-cut the 'nothing' case:

sub optionally {
    @_ >= 1 and @_ <= 2 or fp_croak_arity "1-2";
    my ($f, $maybe_pos) = @_;
    my $pos = $maybe_pos // 0;
    sub {
        if (defined $_[$pos]) {
            goto &$f
        } else {

            # pass on the undef value
            undef
        }
    }
}

# perhaps-based optionally: (XX better name? perhapsionally??)
sub poptionally {
    @_ == 1 or fp_croak_arity 1;
    my ($f) = @_;
    sub {
        if (@_) {
            goto &$f
        } else {

            # pass on the empty list
            ()
        }
    }
}

1
