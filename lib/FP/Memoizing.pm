#
# Copyright (c) 2015-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Memoizing - a functional memoize

=head1 SYNOPSIS

    use FP::Memoizing qw(memoizing memoizing_to_dir);
    use Chj::tempdir;
    my $tmp = do{ mkdir ".tmp"; tempdir ".tmp/" };

    my $count = 0;
    sub f { $count++; $_[0] * 5 }

    *fm = memoizing *f; # memoize in process memory
    *fm2 = memoizing_to_dir $tmp, *f; # memoize to files in ".foo/"

    is fm(3), 15;
    is $count, 1;
    is fm(3), 15;
    is $count, 1;
    is fm(2), 10;
    is $count, 2;
    is fm2(3), 15;
    is $count, 3;
    is fm2(3), 15;
    is $count, 3;


=head1 DESCRIPTION


=head1 TODO

No locking whatsoever is currently being done.

Also, serializes twice in different ways, for the key and the actual
storage. Could Storable be used for the key as well?

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Memoizing;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(memoizing);
our @EXPORT_OK   = qw(memoizing_to_dir);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Chj::TEST;
use Storable qw(nfreeze nstore_fd fd_retrieve);
use Digest;
use FP::Hash qw(hash_cache);
use FP::Carp;

#use Chj::TerseDumper;

# ----------------------------------------------------------------
# For keys:

# sub xnfreeze {
#    @_ == 1 or die "wrong number of arguments";
#     nfreeze ($_[0])
#       // die "can't freeze this: ".TerseDumper ($_[0]);
# }

sub xncanonicalfreeze {
    @_ == 1 or fp_croak_arity 1;
    local $Storable::canonical = 1;
    nfreeze($_[0])
}

#sub xthaw {
#    @_ == 1 or die "wrong number of arguments";
#    thaw ($_[0])
#      // die "corrupted file, can't thaw";
#}

our $freeze_args = \&xncanonicalfreeze;

# XX use TerseDumper instead, to allow for unserializable
# values? But, says things like 'sub { "DUMMY" }' which isn't unique
# for subs, thus nope, won't work either. Perl is a mess in this area,
# right? (Plays nice with the OS? But then doesn't provide for a well
# thought out data exchange.)

# XX what about promises? die, or force them? Don't just be silent
# please

our $digest = sub {
    @_ == 1 or fp_croak_arity 1;
    my $ctx = Digest->new("SHA-256");
    $ctx->add($_[0]);
    my $d = $ctx->b64digest;
    $d =~ tr|/.|--|;
    $d
};

our $digest_args = sub {
    &$digest(&$freeze_args([@_]))
};

# ----------------------------------------------------------------
# For results:

# Just as it is the usual pain with Storable:

# 1. values must be wrapped in an array;
# 2. OS errors versus format errors? No go, right?

sub fh_xnstore {
    @_ == 2 or fp_croak_arity 2;

    # fh, arrayref
    nstore_fd($_[1], $_[0])
        // die "nstore_fd had SOME error (perhaps this?: $!)";

    # << The routine returns "undef" for I/O problems or other internal
    # error, a true value otherwise. Serious errors are propagated as
    # a "die" exception. >> So, what is a serious error, please, and
    # undef doesn't mean I can rely on the error message being in $!,
    # either. Sigh.
}

sub fh_xdeserialize {
    @_ == 1 or fp_croak_arity 1;
    fd_retrieve($_[0]) // die "SOME retrieval error";
}

# ----------------------------------------------------------------

sub memoizing_ {
    @_ == 3 or fp_croak_arity 3;
    my ($fn, $cache, $getcache) = @_;
    sub {
        my @args      = @_;
        my $wantarray = wantarray;
        defined $wantarray or die "memoizing a function in void context";

        # Can't reuse the result from an array context in a scalar
        # context, since we can't assume that $fn would return the
        # last value in scalar context, thus make the context part of
        # the key.
        my $key = ($wantarray ? "n" : "1") . &$digest_args(@_);

        my $vals = &$getcache($cache, $key,
            sub { [$wantarray ? &$fn(@args) : scalar &$fn(@args)] });

        $wantarray ? @$vals : $$vals[-1]
    }
}

sub memoizing {
    @_ == 1 or fp_croak_arity 1;
    my ($fn) = @_;
    memoizing_ $fn, +{}, \&hash_cache
}

use Chj::xopen qw(perhaps_xopen_read);
use Chj::xtmpfile;

# Same API as hash_cache (and like it, only works in scalar context).
# CAREFUL, $k is not checked for subversive values ("../" etc.), only
# use with hashed keys or so!

sub file_cache {
    @_ == 3 or fp_croak_arity 3;
    my ($basepath, $k, $generate) = @_;

    my $path = $basepath . $k;

    if (my ($in) = perhaps_xopen_read $path) {
        my $val = fh_xdeserialize($in);
        $in->xclose;
        $val
    } else {
        my $out = xtmpfile $path;
        my $val = &$generate();
        fh_xnstore($out, $val);
        $out->xclose;
        $out->xputback(0444);
        $val
    }
}

sub memoizing_to_dir {
    @_ == 2 or fp_croak_arity 2;
    my ($dirpath, $f) = @_;
    $dirpath .= "/" unless $dirpath =~ /\/$/s;
    memoizing_ $f, $dirpath, \&file_cache
}

sub tests_for {
    @_ == 1 or fp_croak_arity 1;
    my ($memoizing) = @_;

    my ($t_count, $f);

    TEST {
        $f = &$memoizing(sub { my ($x) = @_; $t_count++; ($x, $x * $x) });
        [[&$f(1)], $t_count]
    }
    [[1, 1], 1];

    TEST { [[&$f(2)], $t_count] }
    [[2, 4], 2];

    TEST { [[&$f(2)], $t_count] }
    [[2, 4], 2];

    TEST { [[scalar &$f(2)], $t_count] }
    [[4], 3];

    TEST {
        my $f = &$memoizing(sub { $t_count++; undef });
        [&$f(undef), &$f(undef), scalar &$f(undef), scalar &$f(undef)]
    }
    [undef, undef, undef, undef];

    TEST {
        my $r = [[scalar &$f(2)], $t_count];
        undef $f;
        undef $t_count;
        $r
    }
    [[4], 5];
}

tests_for \&memoizing;

{
    my $tdir = ".FP-Memoizing-tests";

    TEST {
        mkdir $tdir;
    }
    1;

    tests_for sub {
        my ($f) = @_;
        &memoizing_to_dir($tdir, $f);
    };

    TEST {
        require File::Path;
        File::Path::remove_tree $tdir;
    }
    6;
}

1
