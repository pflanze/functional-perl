#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
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
#@ISA="Exporter"; require Exporter;
#@EXPORT=qw();
#@EXPORT_OK=qw();
#%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
use Sub::Call::Tail;

{
    package PFLANZE::Cost;
    use FP::Array ":all";
    use FP::Struct [qw(name is_purchaseable basecosts val)];
    method cost ($index) {
        $$self{_cost} ||= do {
            add($self->val,
                map {
                    $$index{$_}->cost ($index)
                } @{$self->basecosts}
               );
        }
    }
    _END_
}
{
    package PFLANZE::Totalcost;
    use FP::Array_sort ":all";
    use FP::Struct [qw(costs)];
    method range () {
        @{$$self{costs}} or die "no costs given";#
        my $index;
        for (@{$$self{costs}}) {
            if (defined (my $name= $_->name)) {
                $$index{$name}= $_
            }
        }
        my $purchaseable= [grep { $_->is_purchaseable } @{$$self{costs}}];
        @$purchaseable or die "no purchaseable costs";#
        local our $all= array_sort
          ( $purchaseable,
            on the_method ("cost",$index), \&number_cmp );
        (@$all == 1
         ? $$all[0]->cost ($index)
         : $$all[0]->cost ($index)."..".$$all[-1]->cost($index)),
    }
    _END_
}

