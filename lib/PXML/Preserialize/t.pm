#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

PXML::Preserialize::t -- tests for PXML::Preserialize

=head1 SYNOPSIS

=head1 DESCRIPTION

    # is tested by `t/require_and_run_tests`

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package PXML::Preserialize::t;

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Chj::TEST;
use PXML qw(pxmlbody);

use PXML::Preserialize qw(pxmlfunc pxmlpre);
use PXML::XHTML qw(A B);

my $link_normal = sub {
    my ($href,$body)=@_;
    A {href=> $href}, $body
};

my $link_fast = pxmlfunc {
    my ($href,$body)=@_; # can take up to 10[?] arguments.
    A {href=> $href}, $body
};

# the `2` is the number of arguments
my $link_fast2 = pxmlpre 2, $link_normal;

# these expressions are all returing the same result, but the first
# is slower then the others:
my $res= '<a href="http://foo"><b>Foo</b>Bar</a>';
TEST{ &$link_normal("http://foo", [B("Foo"), "Bar"])->string } $res;

TEST{ &$link_fast("http://foo", [B("Foo"), "Bar"])->string } $res;
TEST{ &$link_fast2("http://foo", [B("Foo"), "Bar"])->string } $res;

TEST{ pxmlfunc { 1 } ->()->string }
  '1';
TEST{ pxmlfunc { [ 1, 2] } ->()->string }
  '12';
TEST{ pxmlfunc { pxmlbody 3, 2 } ->()->string }
  '32';

TEST_EXCEPTION {
    pxmlfunc {
        my ($loc,$body) = @_;
        A {href=> "http://$loc"}, $body
          # yes, already *that* is forbidden.
    }
}
  "tried to access a PXML::Preserialize::Argument object";

TEST_EXCEPTION {
    pxmlfunc {
        my ($loc,$body) = @_;
        A {href=> $loc}, 0-$body
    }
}
  "tried to access a PXML::Preserialize::Argument object";

TEST_EXCEPTION {
    pxmlfunc {
        my ($loc,$body) = @_;
        A {href=> $loc},  $loc ? $body : 1
    }
}
  "tried to access a PXML::Preserialize::Argument object";


1
