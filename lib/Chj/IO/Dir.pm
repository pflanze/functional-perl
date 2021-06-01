#
# Copyright (c) 2003-2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::IO::Dir

=head1 SYNOPSIS

=head1 DESCRIPTION

See L<Chj::xopendir>.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::IO::Dir;

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use Symbol;
use Carp;
use Chj::singlequote ();
use POSIX qw(EEXIST EBADF ENOENT);
use FP::Carp;

my %metadata;    # -> [ is_open, path ]
$foo::foo = \%metadata;

sub path {
    my $self = shift;
    $metadata{ pack "I", $self }[1]
}

sub xopendir {
    my $class = shift;
    my $hdl   = gensym;
    $! = undef;
    if (opendir $hdl, $_[0]) {
        bless $hdl, $class;
        $metadata{ pack "I", $hdl } = [1, $_[0]];
        return $hdl;
    } else {
        croak "xopendir " . Chj::singlequote::singlequote_many(@_) . ": $!";
    }
}

# *new = \&xopendir;  really? no.

sub opendir {
    my $class = shift;
    my $hdl   = gensym;
    $! = undef;
    if (opendir $hdl, $_[0]) {
        bless $hdl, $class;
        $metadata{ pack "I", $hdl } = [1, $_[0]];
        return $hdl;
    } else {
        undef
    }
}

sub perhaps_opendir {
    my $class = shift;
    $! = undef;
    if (defined(my $fh = $class->opendir(@_))) {
        $fh
    } else {
        ()
    }
}

# (adapted copy of perhaps_xopen of File.pm)
# die on all errors except ENOENT
sub perhaps_xopendir {
    my $proto = shift;
    if (my ($fh) = $proto->perhaps_opendir(@_)) {
        $fh
    } elsif ($! == ENOENT) {
        ()
    } else {
        croak "xopen @_: $!";
    }
}

sub new {
    my $class = shift;
    my $self  = gensym;
    bless $self, $class
}

sub read {
    my $self = shift;
    $! = undef;
    readdir $self
}

sub xread {
    my $self = shift;
    $! = undef;

    # ^ Needed, CORE::readdir will not set it to 0. Thus maybe it will
    # not even set any error? Hm, well, at least on end of dir it sets
    # it to Bad file descriptor.
    if (wantarray) {    ## no critic
        my $res = [CORE::readdir $self];

        # we *hope* that [ ] will never copy until the end as opposed
        # to @res = which *might* (well probably (or I think IIRC I've
        # even tested and confirmed it) does) copy all elements.
        if ($!) {
            croak "xread: $!";
        }
        @$res
    } else {
        my $res = CORE::readdir $self;
        if ($! and $! != EBADF) {
            croak "xread: $!";

    #croak "xread: $! (".($!+0).")";   ## exception objects would still be coool
        }
        $res
    }
}

sub nread {    # ignore . and .. entries
    my $self = shift;
    $! = undef;
    if (wantarray) {    ## no critic
        grep { $_ ne '.' and $_ ne '..' } readdir $self
    } else {
        while (defined(my $item = readdir $self)) {
            return $item unless $item eq '.' or $item eq '..';
        }
        undef
    }
}

sub xnread {
    my $self = shift;
    $! = undef;
    if (wantarray) {    ## no critic
        my $res = [grep { $_ ne '.' and $_ ne '..' } readdir $self];
        @$res
    } else {
        while (defined(my $item = readdir $self)) {
            return $item unless $item eq '.' or $item eq '..';
        }
        undef
    }
}

sub telldir {
    my $self = shift;
    $! = undef;
    CORE::telldir $self
}

sub seekdir {
    my $self = shift;
    @_ == 1 or fp_croak_arity 1;
    my ($pos) = @_;
    $! = undef;
    CORE::seekdir $self, $pos
}

sub xseekdir {
    my $self = shift;
    @_ == 1 or fp_croak_arity 1;
    my ($pos) = @_;
    $! = undef;
    CORE::seekdir $self, $pos or croak "xseekdir (UNTESTED): $!";    ##
}

sub xrewind {
    my $self = shift;
    $! = undef;
    CORE::seekdir $self, 0 or croak "xrewind (UNTESTED): $!";        ##
}

sub xclose {
    my $self = shift;

    #(maybe check metadata is_open first? not really useful)
    $! = undef;
    closedir $self or croak "xclose: $!";
    $metadata{ pack "I", $self }[0] = 0
}

sub DESTROY {
    my $self = shift;
    local ($@, $!, $?, $_);
    if ($metadata{ pack "I", $self }[0]) {
        closedir $self or carp "$self DESTROY: $!";
    }
    delete $metadata{ pack "I", $self };
}

1;
