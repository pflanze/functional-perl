#
# Copyright (c) 2014-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::Htmlgen::Cost

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FunctionalPerl::Htmlgen::Cost;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental "signatures";
use Sub::Call::Tail;

#use Exporter "import";
#@EXPORT = qw();
#@EXPORT_OK = qw();
#%EXPORT_TAGS = (all => [@EXPORT,@EXPORT_OK]);

package FunctionalPerl::Htmlgen::Cost::_::Cost {
    use FP::Array ":all";

    use FP::Struct [qw(name is_purchaseable basecosts val)];

    sub cost ($self, $index) {
        $$self{_cost} ||= do {
            add($self->val,
                map { $$index{$_}->cost($index) } @{ $self->basecosts });
        }
    }
    _END_
}

package FunctionalPerl::Htmlgen::Cost::_::Totalcost {
    use FP::Array_sort ":all";

    use FP::Struct [qw(costs)];

    sub range($self) {
        @{ $$self{costs} } or die "no costs given";    #
        my $index;
        for (@{ $$self{costs} }) {
            if (defined(my $name = $_->name)) {
                $$index{$name} = $_
            }
        }
        my $purchaseable = [grep { $_->is_purchaseable } @{ $$self{costs} }];
        @$purchaseable or die "no purchaseable costs";    #
        local our $all
            = array_sort($purchaseable, on the_method("cost", $index),
            \&real_cmp);
        (     @$all == 1
            ? $$all[0]->cost($index)
            : $$all[0]->cost($index) . ".." . $$all[-1]->cost($index))
    }
    _END_
}

