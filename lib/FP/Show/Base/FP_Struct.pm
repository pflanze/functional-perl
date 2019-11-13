#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Show::Base::FP_Struct

=head1 SYNOPSIS

 {
     package Foo;
     use FP::Struct ["a","b"],
       'FP::Show::Base::FP_Struct';
     _END_
 }
 use FP::Show;
 show (Foo->new(1,2)) # => "Foo(1,2)"

=head1 DESCRIPTION

This class simply provides an `FP_Show_show` method that uses
inspection specific to FP::Struct classes to get to know the public
field values of the object it is being called on, and reconstructs a
constructor call based on this information. Meaning, for the typical
`FP::Struct` based class, it will do the right thing.

=cut


package FP::Show::Base::FP_Struct;

use strict; use warnings; use warnings FATAL => 'uninitialized';

sub FP_Show_show {
    my ($self,$show)=@_;
    my $class= ref ($self);
    length $class
      or die "FP_Show_show called on non-object: $self";
    my $fieldnames= do {
        no strict 'refs';
        \@{"${class}::__Struct__fields"}
    };
    my @class_parts= split /::/, $class;
    ($class_parts[-1]."(".
     join(", ",
          map {
              my $fieldname= FP::Struct::field_name($_);
              &$show($self->$fieldname)
          } FP::Struct::all_fields([$class])).
     ")")
}

1
