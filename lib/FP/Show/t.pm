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
use FP::List ":all";

TEST_EXCEPTION {
    my $l= list 100-1, "bottles";
    die "not what we wanted: ".show ($l)
}
  "not what we wanted: list(99, 'bottles')";

TEST { show cons 1, cons 2, 3 }
  'improper_list(1, 2, 3)';

TEST { show improper_list (list (1,3), 2) }
  'improper_list(list(1, 3), 2)';

TEST { show improper_list ([1,3], {foo=> list("bar",sub{"f"})}) }
  'improper_list([1, 3], +{foo => list(\'bar\', sub { "DUMMY" })})';

1
