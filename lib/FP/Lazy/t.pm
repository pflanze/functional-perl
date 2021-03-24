#
# Copyright (c) 2013-2021 Christian Jaeger, copying@christianjaeger.ch
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

use FP::Lazy ":all";
use Chj::TEST;
use FP::Show;
use FP::List;

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

TEST {
    show(lazy { 1 / 0 })
}
'lazy { "DUMMY" }';

TEST {
    show(lazyT { 1 / 0 } "Fun")
}
'lazyT { "DUMMY" } \'Fun\'';

TEST {
    my $v = lazyT { cons(1, 2) } "FP::List::Pair";
    force $v;
    [is_promise($v), show($v)]
}
[1, 'improper_list(1, 2)'];

1
