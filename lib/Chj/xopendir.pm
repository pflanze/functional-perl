#
# Copyright (c) 2003-2014 by Christian Jaeger ch@christianjaeger.ch
# Published under the same terms as perl itself.
#

=head1 NAME

Chj::xopendir

=head1 SYNOPSIS

 use Chj::xopendir;
 {
     my $dir= xopendir "/foo";
     while (defined(my $item=$dir->read)) {
	 print $item;
     }
 } # $dir is closed automatically (issuing a warning on error)

=head1 DESCRIPTION

Something like IO::Dir, but more lightweight (IO::Dir takes about 0.3 seconds
to load on my laptop, whereas this module takes less than 30ms), and with
functions/methods that throw (currently untyped) exceptions on error.


=head1 FUNCTIONS

=over 4

=item xopendir ("path")

Open the given dir or croak on errors. Returns an anonymous symbol
blessed into Chj::xopendir::dir, which can be used both as object
or filehandle (more correctly: anonymous glob) (? always? Perl is a
bit complicated when handling filehandles in indirect object notation).

=back

=head1 CLASS METHODS

=over 4

=item new ("path")

Same as xopendir, but in object oriented notation (overridable).

=back

=head1 OBJECT METHODS

=over 4

=item read

=item xread

Read one dir entry in scalar context, all entries in list context.
xread croaks if it detects an error, though it's quite unsure if
that really works (see also module source).

=item nread

=item xnread

Same as read/xread but discard "." and ".." entries.

=item xclose

Close dirhandle and croak on error. (If not called before descruction
of the object, the filehandle is closed anyway, but only a warning
is issued upon errors in that case.)

=back

=head1 SEE ALSO

L<Chj::xopen>

=cut

#'

package Chj::xopendir;
@ISA='Exporter'; require Exporter;
@EXPORT= qw(xopendir);

use strict;
use Chj::IO::Dir;

sub xopendir($) {
    unshift @_, 'Chj::IO::Dir';
    goto &Chj::IO::Dir::xopendir;
}

1;
