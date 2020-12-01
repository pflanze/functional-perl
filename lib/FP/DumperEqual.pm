#
# Copyright (c) 2014-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::DumperEqual - equality

=head1 SYNOPSIS

    use FP::DumperEqual;

    ok dumperequal [1, [2, 3]], [1, [1+1, 3]];
    ok not dumperequal [1, [2, 3]], [1, [1+2, 3]];

    my $s1 = "stringwithunicode";
    my $s2 = "stringwithunicode";
    utf8::decode($s2);
    # ok not dumperequal $s1, $s2;
    #         ^-- hmm, it used to be the case that this gave false
    ok dumperequal_utf8 $s1, $s2;


=head1 DESCRIPTION

Deep structure equality comparison.

NOTE: using Data::Dumper and thus slow.

For a more proper solution, see FP::Equal

=head1 SEE ALSO

L<FP::Equal>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::DumperEqual;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(dumperequal dumperequal_utf8);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Data::Dumper;
use FP::Carp;

# XX these are expensive, of course. Better solution?

sub dumperequal {
    local $Data::Dumper::Sortkeys = 1;
    my $v0 = shift;
    my $a0 = Dumper($v0);
    for (@_) {
        Dumper($_) eq $a0 or return '';
    }
    1
}

sub dumperequal_utf8 {
    @_ == 2 or fp_croak_arity 2;
    local $Data::Dumper::Sortkeys = 1;

    # compare ignoring utf8 flags on strings
    local $Data::Dumper::Useperl = 1;
    my $v0 = shift;
    my $a0 = Dumper($v0);
    for (@_) {
        Dumper($_) eq $a0 or return '';
    }
    1
}

1
