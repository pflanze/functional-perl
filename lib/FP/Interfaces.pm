#
# Copyright (c) 2013-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Interfaces - implement interfaces

=head1 SYNOPSIS

 {
     package FP::Abstract::Sequence;
     sub fp_interface_method_names {
         qw(fold)
     }
 }

 {
     package FP::Abstract::ExtendedSequence;
     use base qw(FP::Abstract::Sequence); 
     sub fp_interface_method_names {
         my $class= shift;
         (qw(sum), $class->SUPER::fp_interface_method_names)
     }
 }

 {
     package Foo;
     use FP::Interfaces;
     FP::Interfaces::implemented qw(FP::Abstract::ExtendedSequence
                                    FP::Abstract::Pure);

     # FP::Interfaces::implemented adds the given arguments to @ISA
     # and checks that the methods required by those interfaces are
     # actually implemented. It issues warnings for missing methods,
     # in this case that 'sum' is not implemented.

     sub foo {  }
     sub fold {  }
 }

=head1 DESCRIPTION

=head1 SEE ALSO

This implements: L<FP::Abstract::Interface>

=head1 NOTE

This is alpha software! Read the package README.

=cut


package FP::Interfaces;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(require_package
              package_check_possible_interface);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Carp 'croak';


sub require_package ($) {
    my ($package)=@_;
    no strict 'refs';
    if (not keys %{$package."::"}) {
        $package=~ s|::|/|g;
        $package.=".pm";
        require $package
    }
}


sub package_check_possible_interface ($$) {
    my ($caller, $possible_interface_package)= @_;
    if (my $m= UNIVERSAL::can($possible_interface_package,
                              "fp_interface_method_names")) {
        my @missing;
        for my $method (&$m($possible_interface_package)) {
            unless (UNIVERSAL::can($caller, $method)) {
                push @missing, $method
            }
        }
        warn "FP::Interfaces warning: '$caller' does not implement '$possible_interface_package' methods: @missing\n"
            if @missing;
        1
    } else {
        # not an interface
        undef
    }
}


# called fully qualified, i.e. FP::Interfaces::implemented (to avoid
# namespace pollution in classes)
sub implemented {
    my $caller= caller;
    for my $interface (@_) {
        require_package $interface;
        no strict 'refs';
        push @{"${caller}::ISA"}, $interface;
    }
    for my $interface (@_) {
        package_check_possible_interface($caller, $interface)
          // croak "'$interface' does not have a 'fp_interface_method_names' method hence is not an interface";
    }
}


1
