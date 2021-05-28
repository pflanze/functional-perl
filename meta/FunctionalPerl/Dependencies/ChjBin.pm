#
# Copyright (c) 2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::Dependencies::ChjBin

=head1 SYNOPSIS

    use Chj::TEST use => 'FunctionalPerl::Dependencies::ChjBin';
    # or
    use Test::Requires +{
        'FunctionalPerl::Dependencies::ChjBin' => '"trigger-listen"' };
    # or
    #  list in FunctionalPerl::Dependencies's %dependencies

=head1 DESCRIPTION

A way to specify dependencies on tools from
L<chj-bin|https://github.com/pflanze/chj-bin> to the test system.

=head1 SEE ALSO

L<FP::Repl::Dependencies>, L<FunctionalPerl::Dependencies>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FunctionalPerl::Dependencies::ChjBin;

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use FP::Carp;

# XX use ~FP::Memoize instead, but that one should be split into
# in-memory and disk versions.

sub simple_memoize {
    @_ == 2 or fp_croak_arity 2;
    my ($cacheref, $fn) = @_;    # cacheref must be a hash ref
    sub {
        @_ == 1 or fp_croak_arity 1;

        # only one argument supported, and argument must be a string,
        # or identical with regards of that string. And only does
        # scalar context for the result.
        my ($arg) = @_;
        exists $cacheref->{$arg} ? $cacheref->{$arg} : do {
            my $v = $fn->($_[0]);
            $cacheref->{$arg} = $v;
            $v
        }
    }
}

my %which;

sub maybe_which;
*maybe_which = simple_memoize \%which, sub {
    my ($progname) = @_;
    exists $which{$progname} ? $which{$progname} : do {
        my ($prog) = $progname =~ /^([\w-]+)$/
            or die "invalid progname '$progname'";
        my $found = `which $prog`;
        chomp $found;
        my $res = length $found ? $found : undef;
        $which{$progname} = $res;
        $res
    }
};

use Chj::IO::Command;
use Chj::xperlfunc ":all";

my %dir_is_chjbin;

sub dir_is_chjbin;
*dir_is_chjbin = simple_memoize \%dir_is_chjbin, sub {
    my ($dirpath) = @_;

    # using combinedsender just to silence stderr, ok?
    my $in = Chj::IO::Command->new_combinedsender(
        sub {
            xchdir $dirpath;
            use Cwd;
            warn "really checking " . getcwd;
            xexec "git", "remote", "-v"
        }
    );
    my $cnt = $in->xcontent;
    if (0 == $in->xfinish) {

        # OH, must accept _bin, too, my special habit. So ugly.
        (
                   $cnt =~ m{/github\.com/[^/]+/chj-bin(?:\.git)?/? }
                or $cnt =~ m{/_bin/\.git}
        )
    } else {
        undef
    }
};

sub path_is_chjbin {
    my ($path) = @_;
    dir_is_chjbin dirname $path
}

sub import {
    my $class = shift;

    # my ($package, $filename, $line) = caller;
    my (@programs) = @_;
    my @which        = map  { [$_, maybe_which $_] } @programs;
    my @_found       = grep { defined $_->[1] } @which;
    my @_notfound    = map  { $_->[0] } grep { not defined $_->[1] } @which;
    my @found_really = grep { path_is_chjbin $_->[1] } @_found;
    my @found_notfound
        = map { $_->[0] } grep { !path_is_chjbin $_->[1] } @_found;

    # "found" means, the binary from chj-bin is in PATH, thus fine.
    my @notfound = (@_notfound, @found_notfound);
    if (@notfound) {
        my @msgs = (
            (
                @_notfound
                ? "these programs are not available: " . join(", ", @_notfound)
                : ()
            ),
            (
                @found_notfound
                ? "these programs are not from chj-bin: "
                    . join(", ", @found_notfound)
                : ()
            )
        );
        my $msg = join "; ", @msgs;
        die __PACKAGE__ . " import: $msg";
    }
}

# XX what to do if this module is loaded without triggering the
# import? Dangerous play. Alarm handler? Another kind of hook?

1
