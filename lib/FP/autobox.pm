#
# Copyright (c) 2019-2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::autobox

=head1 SYNOPSIS

    use FP::autobox;

    is [12,4,2]->product, 96;

    my $arr = [55,10];
    is ref($arr), "ARRAY";

    use FP::Div ":all"; use FP::Ops ":all";
    is $arr->map(\&inc)->reduce(\&add), 67;

    # Calling methods on arrays 'consumes' the arrays, i.e. makes them
    # blessed and immutable (TODO: offer a FP::autobox::mutable or
    # so?):

    is ref($arr), 'FP::_::PureArray';

    is( (eval { $arr->[0]++; 1 } || regex_substitute(sub{s/\s*at .*//s}, $@)),
        'Modification of a read-only value attempted' );

    is $$arr[0], 55;

=head1 DESCRIPTION

Wouldn't it be cool if an ordinary Perl array could be used as an
L<FP::Abstract::Sequence>? Autobox delivers on that.

This uses L<autobox> underneath. This module does bless the arrays, so
that method calls other than in the lexical scope of the autobox
import work, too.

=head1 TODO

This could be extended to support methods on strings, once a
L<FP::String> module has been implemented, and on hashes for a to-be
implemented L<FP::Abstract::HashMap> protocol.

=head1 SEE ALSO

L<FP::PureArray>, which is transparently loaded to provide the
methods.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::autobox;

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

require FP::PureArray;
require autobox;

our @ISA = "autobox";

sub import {
    my ($pack, @args) = @_;
    my %args = @args;
    if (not $args{ARRAY}) {
        push @_, ARRAY => 'FP::PureArray::autobox';
    }
    if (not $args{HASH}) {
        push @_, HASH => 'FP::PureHash::autobox';
    }
    my $m = $pack->can("SUPER::import") or die "bug";
    goto $m
}

1
