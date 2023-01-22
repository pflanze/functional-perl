#
# Copyright (c) 2022 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#
#

=head1 NAME

FP::List::t

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FP::List::t;
use strict;
use utf8;
use warnings;
use warnings FATAL => 'uninitialized';
#use experimental 'signatures';

use FP::List;
use FP::PureArray;
use Chj::TEST;

TEST { list(5, 7, 8, 9, 11, 13, 12, 10)->split(sub { not($_[0] % 2) }) }
list(purearray(5, 7), purearray(9, 11, 13), purearray());
TEST { list(5, 7, 8, 9, 11, 13, 12, 10)->split(sub { not($_[0] % 2) }, 1) }
list(purearray(5, 7, 8), purearray(9, 11, 13, 12), purearray(10));
TEST { list(12, 10, 11)->split(sub { not($_[0] % 2) }) }
list(purearray(), purearray(), purearray(11));
TEST { list(12, 10)->split(sub { not($_[0] % 2) }) }
list(purearray(), purearray());


1
