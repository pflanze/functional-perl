#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::singlequote::t -- tests for Chj::singlequote

=head1 SYNOPSIS

 # is tested by `t/require_and_run_tests`

=head1 DESCRIPTION


=cut


package Chj::singlequote::t;

use strict; use warnings FATAL => 'uninitialized';

use Chj::singlequote ":all";
use Chj::TEST;

TEST { with_maxlen 9, sub { singlequote "Darc's place" } }
  "'Darc\\'s...'";

1
