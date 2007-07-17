# Mon Jul 14 07:37:04 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# moved here from Chj::xopendir.
#
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself.
#
# $Id$

=head1 NAME

Chj::IO::Dir

=head1 SYNOPSIS

=head1 DESCRIPTION

See L<Chj::xopendir>.

=cut


package Chj::IO::Dir;

use strict;

use Symbol;
use Carp;
BEGIN {
    if ($^O eq 'linux') {
	eval 'sub EEXIST() {17}; sub EBADF() {9}'; die if $@;
    } else {
	eval 'use POSIX "EEXIST","EBADF"'; die if $@;
    }
}

my %metadata; # -> [ is_open, path ]
$foo::foo=\%metadata;
sub path {
    my $self=shift;
    $metadata{pack "I",$self}[1]
}

sub xopendir {
    my $class=shift;
    my $hdl= gensym;
    if (opendir $hdl,$_[0]) {
	bless $hdl, $class;
	$metadata{pack "I",$hdl}=[1, $_[0]];
	return $hdl;
    }
    else {
	croak "xopendir @_: $!";
    }
}
# *new= \&xopendir;  really? no.

sub opendir {
    my $class=shift;
    my $hdl= gensym;
    if (opendir $hdl,$_[0]) {
	bless $hdl, $class;
	$metadata{pack "I",$hdl}=[1, $_[0]];
	return $hdl;
    }
    else {
	undef
    }
}

sub new {
    my $class=shift;
    my $self= gensym;
    bless $self,$class
}

sub read {
    my $self=shift;
    readdir $self
}
#sub xread {
#    croak "xread not implemented - we cannot (generally) detect errors in readdir on unix";
#}


sub xread {
    my $self=shift;
    $!=0; # NEEDED, CORE::readdir will not set it to 0. Thus maybe it will not even set any error? Hm, well, at least on end of dir it sets it to Bad file descriptor.
    if (wantarray) {
	my $res=[ CORE::readdir $self ];  # we *hope* that [ ] will never copy until the end as opposed to @res= which *might* (well probably (or I think IIRC I've even tested and confirmed it) does) copy all elements.
	if ($!){
	    croak "xread: $!";
	}
	@$res
    } else {
	my $res= CORE::readdir $self;
	if ($! and $! != EBADF){
	    croak "xread: $!";
	    #croak "xread: $! (".($!+0).")";   ## exception objects would still be coool
	}
	$res
    }
}

sub nread { # ignore . and .. entries
    my $self=shift;
    if (wantarray) {
	grep { $_ ne '.' and $_ ne '..' } readdir $self
    } else {
	while (defined (my $item=readdir $self)) {
	    return $item unless $item eq '.' or $item eq '..';
	}
	undef
    }
}
# sub xnread {
#     my $self=shift;
#     $!=0; # sigh, needed
#     if (wantarray) {
# 	my $res= [ grep { $_ ne '.' and $_ ne '..' } readdir $self ];
# 	if ($!){
# 	    croak "xnread: $!";
# 	}
# 	@$res
#     } else {
# 	while (defined (my $item=readdir $self)) {
# 	    return $item unless $item eq '.' or $item eq '..';
# 	}
# 	if ($! and $! != EBADF){ # btw how should we trap a real EBADF ? (at least that should never happen if the directory has really been opened once; EBADF is a user error, reading from an unopened fd, right?)
# 	    croak "xnread: $!";
# 	}
# 	undef
#     }
# }
# cj 10.7.04 fuuuck auch dies geht nimmer (auf perl 5.6.1! ethlife) in manchen fällen. spurious xnread: Datei oder Verzeichnis nicht gefunden at /usr/local/lib/perl/5.6.1/Chj/FileStore/MIndex/NonsortedIterator.pm line 98

sub xnread {
    my $self=shift;
    if (wantarray) {
	my $res= [ grep { $_ ne '.' and $_ ne '..' } readdir $self ];
	@$res
    } else {
	while (defined (my $item=readdir $self)) {
	    return $item unless $item eq '.' or $item eq '..';
	}
	undef
    }
}

sub telldir {
    my $self=shift;
    CORE::telldir $self
}

sub seekdir {
    my $self=shift;
    @_==1 or croak "seekdir: expecting 1 argument";
    my($pos)=@_;
    CORE::seekdir $self,$pos
}

sub xseekdir {
    my $self=shift;
    @_==1 or croak "xseekdir: expecting 1 argument";
    my($pos)=@_;
    CORE::seekdir $self,$pos or croak "xseekdir (UNTESTED): $!";##
}

sub xrewind {
    my $self=shift;
    CORE::seekdir $self,0 or croak "xrewind (UNTESTED): $!";##
}

sub xclose {
    my $self=shift;
    #(maybe check metadata is_open first? not really useful)
    closedir $self or croak "xclose: $!";
    $metadata{pack "I",$self}[0]=0
}

sub DESTROY {
    my $self=shift;
    local ($@,$!);
    if ($metadata{pack "I",$self}[0]) {
	closedir $self
	  or carp "$self DESTROY: $!";
    }
    delete $metadata{pack "I",$self};
}

1;
