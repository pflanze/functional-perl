# Sat Apr 26 19:21:04 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself.
#
# $Id$

# Sun, 30 Nov 2003 23:19:05 +0100
# heieiei. schon wieder ein bug. hatte in xopen_* funktionen optionale params gekillt.
# ACH das geht ja gar nicht beim normalen open. Wurg. Anyway. (sollte in Chj::IO::File::xopen wohl anz argumente checken?)

=head1 NAME

Chj::xopen

=head1 SYNOPSIS

 use Chj::xopen;
 {
     my $file= xopen "<foo.txt";
     while (<$file>) { # default operation. (overload not possible :/)
	 print;
     }
 } # $file is closed automatically (issuing a warning on error)

=head1 DESCRIPTION

Kind of a wrapper around Chj::IO::File / builtin open call.
Simply calls Chj::IO::File->xopen(@_).

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

=item xopen_input EXPR

=item xopen_read EXPR

=item xopen_output EXPR

=item xopen_write EXPR

=item xopen_append EXPR

=item xopen_readwrite EXPR

=item xopen_update EXPR

Those *optionally exported* functions check the one given input
parameter for <>+ chars at the beginning, and either croak if they
don't match the purpose of the function, or prepend the right chars if
missing.

 ** *_input / _output / _readwrite are deprecated,
 use _read / _write / _update instead **

=back

=head1 BUGS

Stuff like >&1 not yet really supported by the above xopen_* functions.

=head1 SEE ALSO

L<Chj::IO::File>, L<Chj::xsysopen>, L<Chj::xopendir>

=cut


# '

package Chj::xopen;
@ISA='Exporter';
require Exporter;
@EXPORT= qw(xopen);
@EXPORT_OK= qw(xopen_input xopen_output  xopen_read xopen_write
	       xopen_append xopen_readwrite
	       xopen_update
	       devnull devzero
	      );
%EXPORT_TAGS= (all=> \@EXPORT_OK);

use strict;
use Carp;

use Chj::IO::File;

sub xopen { ## should i prototype arguments?
    ## wie setzt man eben ein stackframe ignorier?  ah he!  goto & form ? !!!!:
    unshift @_,'Chj::IO::File';
    #goto &{Chj::IO::File->can("xopen")}  or even, (bit faster?):
    goto &Chj::IO::File::xopen;
}

sub xopen_read($) {
    if ($_[0]=~ /^((<)|(>>)|(>)|(\+<)|(\+>))/) {
	croak "xopen_input: mode $1 not allowed"
	  unless $2;
    } elsif (@_==1 and $_[0] eq '-') {
	@_=("<-")
    } else {
	#$_[0]= "<$_[0]";
	#@_= ("<$_[0]");
	#@_= ("<",$_[0]);
	#@_= ("<",@_); oder einfacher
	unshift @_,"<";
    }
    unshift @_,'Chj::IO::File';
    goto &Chj::IO::File::xopen;
}
*xopen_input= \&xopen_read;

sub xopen_write($) {
    if ($_[0]=~ /^((<)|(>>)|(>)|(\+<)|(\+>))/) {
	croak "xopen_output: mode $1 not allowed"
	  unless $3 or $4;
    } elsif (@_==1 and $_[0] eq '-') {
	@_=(">-")
    } else {
	#@_= (">$_[0]");
	#@_= (">",$_[0]);
	unshift @_,">";
    }
    unshift @_,'Chj::IO::File';
    goto &Chj::IO::File::xopen;
}
*xopen_output= \&xopen_write;

sub xopen_append($) {
    if ($_[0]=~ /^((<)|(>>)|(>)|(\+<)|(\+>))/) {
	croak "xopen_append: mode $1 not allowed"
	  unless $3;
    } elsif (@_==1 and $_[0] eq '-') {
	@_=(">>-")
    } else {
	#@_= (">>$_[0]");
	#@_= (">>", $_[0]);
	unshift @_,">>";
    }
    unshift @_,'Chj::IO::File';
    goto &Chj::IO::File::xopen;
}

sub xopen_update($) {
    if ($_[0]=~ /^((<)|(>>)|(>)|(\+<)|(\+>))/) {
	croak "xopen_readwrite: mode $1 not allowed"
	  unless $5 or $6;
    } elsif (@_==1 and $_[0] eq '-') {
	@_=("+<-")
    } else {
	#@_= ("+<$_[0]");
	#@_= ("+<",$_[0]);
	unshift @_, "+<";
    }
    unshift @_,'Chj::IO::File';
    goto &Chj::IO::File::xopen;
}
*xopen_readwrite= \&xopen_update;

#use POSIX qw(O_RDWR);##ach, hab ich überall lazy loading gemacht und nun doch nicht?
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

1;
