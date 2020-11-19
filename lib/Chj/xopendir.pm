#
# Copyright (c) 2003-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::xopendir

=head1 SYNOPSIS

    use Chj::xopendir;
    {
        my $dir = xopendir "/foo";
        while (defined(my $item = $dir->read)) {
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

=item perhaps_opendir ($path)

Try to open given directory path, if successful return the filehandle,
otherwise return () and leave $! set.

=item perhaps_xopendir ($path)

Same as perhaps_opendir but throw exception on all errors except for
ENOENT.

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

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

#'

package Chj::xopendir;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Chj::IO::Dir;
use Exporter 'import';

our @EXPORT = qw(xopendir perhaps_opendir perhaps_xopendir);

sub xopendir($) {
    unshift @_, 'Chj::IO::Dir';
    goto &Chj::IO::Dir::xopendir;
}

sub perhaps_opendir($) {
    unshift @_, 'Chj::IO::Dir';
    goto &Chj::IO::Dir::perhaps_opendir;
}

sub perhaps_xopendir($) {
    unshift @_, 'Chj::IO::Dir';
    goto &Chj::IO::Dir::perhaps_xopendir;
}

1;
