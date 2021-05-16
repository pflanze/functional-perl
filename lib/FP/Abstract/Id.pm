#
# Copyright (c) 2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Abstract::Id - identity protocol

=head1 SYNOPSIS

=head1 DESCRIPTION

This protocol handles identification for values (objects). An
identifier is a string. Classes implementing this protocol must
provide a `FP_Id_id' method that takes no other arguments and returns
the identifier for the set of objects which are considered identical
by the class.

The identifier may be used for sorting (e.g. L<FP::Collection> uses it
to determine the sort order of the elements in L<FP::Show>::show). It
doesn't need to be human readable (thus could be implemented via
hashing) but it might be useful if it is.

=head1 SEE ALSO

L<FP::Collection>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Abstract::Id;
use strict;
use utf8;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

sub FP_Interface__method_names {
    my $class = shift;
    qw(FP_Id_id)
}

1
