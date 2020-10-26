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

=item xeffectiveuserhome ()

Just the getpwuid setting. Throws unimplemented exception on Windows
(Raspberry, not Cygwin Perl).

=item xsafehome ()

Always take xeffectiveuserhome (unless on Windows, in which case this
is currently the same as xhome), but is asserting that HOME is the
same if set.

=item xhome ()

Take HOME if set (with assertments), otherwise xeffectiveuserhome.

=back

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package Chj::xhome;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(xhome);
@EXPORT_OK=qw(xHOME
              xeffectiveuserhome
              xsafehome);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

sub xHOME () {
    defined (my $home=$ENV{HOME})
      or die "environment variable HOME is not set";
    length ($home)
      or die "environment variable HOME is the empty string";
    $home
      or die "environment variable HOME is false";
    if ($^O eq 'MSWin32') {
        $home=~ m|^[a-z]+:|i # XX correct letter syntax?
            or die "environment variable HOME does not start with a drive designator: '$home'";
    } else {
        $home=~ m|^/|
            or die "environment variable HOME does not start with a slash: '$home'";
    }
    $home
}

sub xeffectiveuserhome () {
    my $uid= $>;
    my ($name,$passwd,$_uid,$gid,
        $quota,$comment,$gcos,$dir,$shell,$expire)
      = getpwuid $uid
        or die "unknown user for uid $uid";
    $dir
}

sub xsafehome () {
    if ($^O eq 'MSWin32') {
        # XX or how to look it up on Windows again? If implemented, update pod.
        xhome()
    } else {
        my $effectiveuserhome= xeffectiveuserhome;
        if (my $e= $ENV{HOME}) {
            $e eq $effectiveuserhome
              or die "HOME environment variable is set to something other ".
                "than the effective user home: '$e' vs. '$effectiveuserhome'";
        }
        $effectiveuserhome
    }
}

sub xhome () {
    if ($ENV{HOME}) {
        xHOME
    } else {
        # what about setting $ENV{HOME} in this case?
        xeffectiveuserhome
    }
}


1
