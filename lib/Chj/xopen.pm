#
# Copyright (c) 2003-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::xopen

=head1 SYNOPSIS

 use Chj::xopen;
 {
     my $in= xopen_read "foo.txt";
     my $out= glob_to_fh(*STDOUT,"utf-8");
     local $_;
     while (<$in>) { # default operation. (overload not possible :/)
	 $out->xprint($_); # print, throwing an exception on error
     }
     $out->xclose; # close explicitely, throwing an exception on error
 }
   # $in and $out are closed automatically in any case
   # (issuing a warning on error)

=head1 DESCRIPTION

Constructors around Chj::IO::File.

=head1 FUNCTIONS

=over 4

=item xopen ( EXPR | MODE,LIST )

Open the given file like the perl builtin "open" or croak on errors.
Returns an anonymous symbol
blessed into Chj::xopen::file, which can be used both as object
or filehandle (more correctly: anonymous glob) (? always? Perl is a
bit complicated when handling filehandles in indirect object notation).

(BTW, note that perl won't give an error if you open a directory instead
of a file for reading. The returned filehandle will give empty results if either
used with read or readdir. That's true for perl 5.005x - 5.6.1 on linux.)

=item xopen_read EXPR

=item xopen_write EXPR

=item xopen_append EXPR

=item xopen_update EXPR

Those *optionally exported* functions check the one given input
parameter for <>+ chars at the beginning, and either croak if they
don't match the purpose of the function, or prepend the right chars if
missing.

=back

=head1 BUGS

Stuff like >&1 not yet really supported by the above xopen_* functions.

=head1 SEE ALSO

L<Chj::IO::File>, L<Chj::xsysopen>, L<Chj::xopendir>

=cut


package Chj::xopen;
@ISA='Exporter';
require Exporter;
@EXPORT= qw(xopen xopen_read);
@EXPORT_OK= qw(xopen_write xopen_append xopen_update
	       perhaps_open_read perhaps_xopen_read
	       devnull devzero
	       glob_to_fh
	       fd_to_fh
	       inout_fd_to_fh
	       input_fd_to_fh
	       output_fd_to_fh
	       fh_to_fh
	      );
%EXPORT_TAGS= (all=> [@EXPORT, @EXPORT_OK]);

use strict;
use Carp;

use Chj::IO::File;

sub glob_to_fh ($;$) {
    my ($glob, $maybe_layer_or_encoding)=@_;
    my $fh= bless (*{$glob}{IO}, "Chj::IO::File");
    $fh->perhaps_set_layer_or_encoding($maybe_layer_or_encoding);
    $fh
}


# --------------------------------------------------
# Turn unix fd-s to Chj::IO::File handles

# `open my $fh, '<&'.$fd` dup's the file descriptor, so use
# IO::Handle's `new_from_fd` instead

use IO::Handle;

sub fd_to_fh ($$;$) {
    my ($fd, $mode, $maybe_layer_or_encoding)=@_;
    $fd=~ /^\d+\z/s
      or die "fd argument must be a natural number";
    my $fh= IO::Handle->new_from_fd($fd, $mode);
    bless $fh, "Chj::IO::File";
    $fh->perhaps_set_layer_or_encoding($maybe_layer_or_encoding);
    $fh
}

sub inout_fd_to_fh ($;$) {
    my ($fd, $maybe_layer_or_encoding)=@_;
    fd_to_fh $fd, "rw", $maybe_layer_or_encoding
}

sub input_fd_to_fh ($;$) {
    my ($fd, $maybe_layer_or_encoding)=@_;
    fd_to_fh $fd, "r", $maybe_layer_or_encoding
}

sub output_fd_to_fh ($;$) {
    my ($fd, $maybe_layer_or_encoding)=@_;
    fd_to_fh $fd, "w", $maybe_layer_or_encoding
}


# --------------------------------------------------
# Wrap a Perl fh of another kind (class) as a Chj::IO::File handle,
# for cases where reblessing is not ok.

sub fh_to_fh ($) {
    my ($fh)=@_;
    require Chj::IO::WrappedFile;
    Chj::IO::WrappedFile->new($fh)
}


# --------------------------------------------------
# Open filehandles from paths:


sub xopen {
    unshift @_,'Chj::IO::File';
    goto &Chj::IO::File::xopen; # (evil?, should it use ->can to remain OO based?)
}

sub xopen_read($) {
    if ($_[0]=~ /^((<)|(>>)|(>)|(\+<)|(\+>))/) {
	croak "xopen_read: mode $1 not allowed"
	  unless $2; # XXX isn't this wong? Too many parens above?
    } elsif (@_==1 and $_[0] eq '-') {
	@_=("<-")
    } else {
	unshift @_,"<";
    }
    unshift @_,'Chj::IO::File';
    goto &Chj::IO::File::xopen;
}

# XX ok to simply use the 3-argument open and never allow 2-open
# strings at all? See how I seem to have gotten it wrong anyway, above!
sub perhaps_xopen_read ($) {
    @_==1 or die "wrong number of arguments";
    unshift @_,"<";
    unshift @_,'Chj::IO::File';
    goto &Chj::IO::File::perhaps_xopen;
}

sub perhaps_open_read ($) {
    @_==1 or die "wrong number of arguments";
    unshift @_,"<";
    unshift @_,'Chj::IO::File';
    goto &Chj::IO::File::perhaps_open;
}


sub xopen_write($) {
    if ($_[0]=~ /^((<)|(>>)|(>)|(\+<)|(\+>))/) {
	croak "xopen_write: mode $1 not allowed"
	  unless $3 or $4;
    } elsif (@_==1 and $_[0] eq '-') {
	@_=(">-")
    } else {
	unshift @_,">";
    }
    unshift @_,'Chj::IO::File';
    goto &Chj::IO::File::xopen;
}

sub xopen_append($) {
    if ($_[0]=~ /^((<)|(>>)|(>)|(\+<)|(\+>))/) {
	croak "xopen_append: mode $1 not allowed"
	  unless $3;
    } elsif (@_==1 and $_[0] eq '-') {
	@_=(">>-")
    } else {
	unshift @_,">>";
    }
    unshift @_,'Chj::IO::File';
    goto &Chj::IO::File::xopen;
}

sub xopen_update($) {
    if ($_[0]=~ /^((<)|(>>)|(>)|(\+<)|(\+>))/) {
	croak "xopen_update: mode $1 not allowed"
	  unless $5 or $6;
    } elsif (@_==1 and $_[0] eq '-') {
	@_=("+<-")
    } else {
	unshift @_, "+<";
    }
    unshift @_,'Chj::IO::File';
    goto &Chj::IO::File::xopen;
}

our $devnull;
sub devnull {
    $devnull ||= do {
	require POSIX; import POSIX "O_RDWR";
	Chj::IO::File->xsysopen("/dev/null",&O_RDWR)
      }
}
our $devzero;
sub devzero {
    $devzero ||= do {
	require POSIX; import POSIX "O_RDWR";
	Chj::IO::File->xsysopen("/dev/zero",&O_RDWR)
      }
}

1
