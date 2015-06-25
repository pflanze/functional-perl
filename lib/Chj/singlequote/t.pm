#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
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
