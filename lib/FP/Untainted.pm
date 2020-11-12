#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Untainted - functional untainting

=head1 SYNOPSIS

    use FP::Untainted;
    exec untainted($ENV{CMD}); # doesn't change the taint flag on $ENV{CMD}

    use FP::Untainted qw(untainted_with);
    exec untainted_with($ENV{CMD}, qr/^\w+$/s); # dito
    # NOTE that the ^ and $ anchors are essential if you want to make
    # sure the whole string matches!

    # or, (but this doesn't force the /s flag)
    exec untainted_with($ENV{CMD}, '^\w+$');

    use FP::Untainted qw(is_untainted);
    # complement of Scalar::Util's 'tainted'

=head1 DESCRIPTION

L<Taint::Util> offers `untaint`, but it changes its argument. This
module provides a pure function to do the same (it (currently) uses a
regex match instead of XS to do so, though.)

Should this module stay? Vote your opinion if you like.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Untainted;
@ISA = "Exporter";
require Exporter;
@EXPORT      = qw(untainted);
@EXPORT_OK   = qw(untainted_with is_untainted);
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use Chj::TEST;

sub untainted ($) {
    $_[0] =~ /(.*)/s or die "??";
    $1
}

sub untainted_with ($$) {
    my ($v, $re) = @_;
    $v =~ /($re)/ or die "untainted_with: does not match regex $re: '$v'";
    $1
}

TEST { untainted_with "Foo",  qr/\w+/s } "Foo";
TEST { untainted_with "Foo ", qr/\w+/s } "Foo";
TEST_EXCEPTION { untainted_with "Foo ", qr/^\w+$/s }
'untainted_with: does not match regex (?^s:^\\w+$): \'Foo \'';

TEST { untainted_with "Foo",  '\w+' } "Foo";
TEST { untainted_with "Foo ", '\w+' } "Foo";
TEST_EXCEPTION { untainted_with "Foo ", '^\w+$' }    # /s missing.
'untainted_with: does not match regex ^\\w+$: \'Foo \'';

use Scalar::Util 'tainted';

sub is_untainted ($) {
    not tainted $_[0]
}

1
