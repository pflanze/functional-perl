#
# Copyright (c) 2019-2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Docstring::t -- tests for FP::Docstring

=head1 SEE ALSO

L<FP::Docstring>

=cut

package FP::Docstring::t;
use strict;
use utf8;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw();
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Docstring;
use Chj::TEST;

# try to trick the parser:
TEST {
    docstring(sub { __ "hi\');"; $_[0] + 1 })
}
'hi\');';
TEST {
    docstring(sub { __ "hi\");"; $_[0] + 1 })
}
'hi");';

# get the quoting right:
TEST {
    docstring(sub { __ '($foo) -> hash'; $_[0] + 1 })
}
'($foo) -> hash';
TEST {
    docstring(sub { __ '("$foo")'; $_[0] + 1 })
}
'("$foo")';
TEST {
    docstring(sub { __ '(\'$foo\')'; $_[0] + 1 })
}
'(\'$foo\')';
TEST {
    docstring sub {
        __ '($str, $token, {tokenargument => $value,..})-> $str
        re-insert hidden parts';
        1
    }
}
'($str, $token, {tokenargument => $value,..})-> $str
        re-insert hidden parts';

1
