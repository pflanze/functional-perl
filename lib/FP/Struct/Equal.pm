#
# Copyright (c) 2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Struct::Equal -- automatic Equal protocol implementation

=head1 SYNOPSIS

    package FP_Struct_Equal_Example::Foo {

        use FP::Struct ["a","b"],
          'FP::Struct::Equal';

        _END_
    }

    FP_Struct_Equal_Example::Foo::constructors->import;
    use FP::Equal;
    ok equal(Foo(1, [1+1, 3]), Foo(1, [2, 3]));
    ok not equal(Foo(1, 1+1), Foo(1, [3]));

=head1 DESCRIPTION

This class, when listed as a superclass of an L<FP::Struct>,
automatically implements the L<FP::Abstract::Equal> protocol
(i.e. generates an `FP_Equal_equal` method that uses inspection
specific to FP::Struct classes to get to know the public field values
of the object it is being called on, and reconstructs a constructor
call based on this information.) This will be the right thing for the
typical `FP::Struct` based class that don't have or mutate hidden
fields or want to exclude some fields from equality tests.

=head1 SEE ALSO

Creates implementations for: L<FP::Abstract::Equal>

L<FP::Struct::Show>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FP::Struct::Equal;

use strict; use warnings; use warnings FATAL => 'uninitialized';

use base 'FP::Abstract::Equal';
use FP::Equal ();

sub FP_Equal_equal {
    my ($self, $b) = @_;
    my $class = ref ($self);
    length $class
      or die "FP_Show_show called on non-object: $self";
    my $fieldnames = do {
        no strict 'refs';
        \@{"${class}::__Struct__fields"}
    };
    # XX is all_fields slow, probably? Optim?
    for (FP::Struct::all_fields([$class])) {
        my $fieldname = FP::Struct::field_name($_);
        FP::Equal::equal($self->$fieldname, $b->$fieldname)
            or return 0
    }
    1
}

1
