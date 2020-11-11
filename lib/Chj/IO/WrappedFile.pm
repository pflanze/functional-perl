#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::IO::WrappedFile

=head1 SYNOPSIS

    use Chj::xopen 'fh_to_fh';
    my $fh = fh_to_fh ($some_pty_or_so);
    # which is the same as:
    my $fh2 = Chj::IO::WrappedFile->new ($some_pty_or_so);

    # $fh and $fh2 are Chj::IO::WrappedFile objects *containing*
    # $some_pty_or_so
    $fh->dup2(0) # etc., all Chj::IO::File methods

=head1 DESCRIPTION

This is a type wrapper to provide the Chj::IO::File methods for all
kinds of Perl filehandles.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package Chj::IO::WrappedFile;

use strict; use warnings; use warnings FATAL => 'uninitialized';

use base 'Chj::IO::File';

sub new {
    my $class = shift;
    bless [@_], $class
}

sub fh {
    $_[0][0]
}


1
