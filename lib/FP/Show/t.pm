#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Show::t

=head1 SYNOPSIS

=head1 DESCRIPTION

Run by test suite

=cut


package FP::Show::t;

use strict; use warnings FATAL => 'uninitialized';

use Chj::TEST;

use FP::Show; # exports 'show'
use FP::List;

TEST_EXCEPTION {
    my $l= list 100-1, "bottles";
    die "not what we wanted: ".show ($l)
} 'not what we wanted: list(99, "bottles")';

1
