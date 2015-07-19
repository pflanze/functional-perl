#
# Copyright (c) 2013-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

PXML::Serialize::t -- tests for PXML::Serialize

=head1 SYNOPSIS

=head1 DESCRIPTION

 # is tested by `t/require_and_run_tests`

=cut


package PXML::Serialize::t;

use strict; use warnings FATAL => 'uninitialized';

use Chj::TEST;
use PXML::Serialize qw(pxml_print_fragment_fast);
use PXML::XHTML ":all";

TEST_STDOUT { pxml_print_fragment_fast ["abc",P(2)], *STDOUT }
  'abc<p>2</p>';
TEST_STDOUT { pxml_print_fragment_fast ["abc"], *STDOUT }
  'abc';

1
