#
# Copyright (c) 2013-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Lazy::t -- tests for FP::Lazy

=head1 SYNOPSIS

=head1 DESCRIPTION

Had to move them here to avoid dependency cycle.

=cut

package FP::Lazy::t;

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use FP::Lazy;
use Chj::TEST;

TEST {
    our $foo = "";

    sub moo {
        my ($bar) = @_;
        local $foo = "Hello";
        lazy {"$foo $bar"}
    }
    moo("you")->force
}
" you";

1
