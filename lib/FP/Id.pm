#
# Copyright (c) 2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Id

=head1 SYNOPSIS

    use FP::Id;
    is id("a"),"a";
    my $a = [];
    my $b = [];
    ok(id($a) eq id($a));
    ok not id($a) eq id($b);
    # Objects can implement FP::Abstract::Id to override using their
    # pointer as the id. *Or* should the default be the show() string?

=head1 DESCRIPTION

=head1 SEE ALSO

L<FP::Abstract::Id>.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Id;
use strict;
use utf8;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(id);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Carp;
use Scalar::Util qw(blessed);

# XX confusion with the `identity` function? What other name would be
# appropriate?
sub id {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
    if (blessed $v) {
        if (defined(my $m = $v->can("FP_Id_id"))) {
            $m->($v)
        } else {
            $v +0
        }
    } elsif (length ref $v) {
        $v +0
    } else {
        "$v"
    }
}

1
