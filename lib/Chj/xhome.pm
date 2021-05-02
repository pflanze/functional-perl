#
# Copyright (c) 2010-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::xhome

=head1 SYNOPSIS

=head1 DESCRIPTION

Get the user's home directory in a safe manner. 

=over 4

=item xHOME ()

Just the $HOME env var, dieing if not set, and also checked against a
couple assertments.

In taint mode, is tainted.

=item xeffectiveuserhome ()

Just the getpwuid setting. Throws unimplemented exception on Windows
(Raspberry, not Cygwin Perl).

Is not tainted.

=item xsafehome ()

Always take xeffectiveuserhome (unless on Windows, in which case this
is currently the same as xhome), but is asserting that HOME is the
same if set.

Is untainted except on Windows where it's tainted.

=item xhome ()

Tries $ENV{HOME} then glob "~" if exists (with assertments), otherwise
xeffectiveuserhome.

In taint mode, can be (and usually is) tainted.

=back

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::xhome;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT    = qw(xhome);
our @EXPORT_OK = qw(xHOME
    xeffectiveuserhome
    xsafehome);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Carp;
use FP::Docstring;

# use File::HomeDir qw(home);

# But File::HomeDir is not installed with either Cygwin or Strawberry
# Perl. Also, HomeDir's `home` returns undef for non-existing paths.

sub xcheck_home {
    my ($home) = @_;
    length($home) or die "environment variable HOME is the empty string";
    $home         or die "environment variable HOME is false";
    if ($^O eq 'MSWin32') {
        $home =~ m|^[a-z]+:|i    # XX correct letter syntax?
            or die
            "environment variable HOME does not start with a drive designator: '$home'";
    } else {
        $home =~ m|^/|
            or die
            "environment variable HOME does not start with a slash: '$home'";
    }
}

sub xHOME {
    @_ == 0 or fp_croak_arity 0;
    defined(my $home = $ENV{HOME})
        or die "environment variable HOME is not set";
    xcheck_home $home;
    $home
}

sub xeffectiveuserhome {

    @_ == 0 or fp_croak_arity 0;
    __ "is untainted";

# (Don't bother about caching, premature opt & dangerous.)
    my $uid = $>;
    my (
        $name,    $passwd, $_uid, $gid,   $quota,
        $comment, $gcos,   $dir,  $shell, $expire
        )
        = getpwuid $uid
        or die "unknown user for uid $uid";
    $dir
}

sub xsafehome {
    @_ == 0 or fp_croak_arity 0;
    __ "is untainted except on Windows where it's tainted";
    if ($^O eq 'MSWin32') {

        # XX or how to look it up on Windows again? If implemented, update pod.
        xhome()
    } else {
        my $effectiveuserhome = xeffectiveuserhome;
        if (my $e = $ENV{HOME}) {
            $e eq $effectiveuserhome
                or die "HOME environment variable is set to something other "
                . "than the effective user home: '$e' vs. '$effectiveuserhome'";
        }
        $effectiveuserhome
    }
}

our $warned = 0;

sub xchecked_home {
    @_ == 2 or fp_croak_arity 2;
    my ($home, $what) = @_;
    xcheck_home $home;
    if (-d $home) {
        $home
    } else {
        warn "$what: dir '$home' does not exist, falling back to getpwuid"
            unless $warned++;
        undef
    }
}

sub maybe_HOME {
    __ "is tainted";
    if (my $home = $ENV{HOME}) {
        xchecked_home $home, '$ENV{HOME}'
    } else {
        undef
    }
}

sub maybe_globhome {
    __ "is tainted";
    my ($home) = glob "~";
    if (defined $home) {
        xchecked_home $home, "glob '~'";
    } else {
        undef
    }
}

sub xhome {
    @_ == 0 or fp_croak_arity 0;
    maybe_HOME() // maybe_globhome() // xeffectiveuserhome()
}

1
