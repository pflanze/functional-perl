#
# Copyright (c) 2019-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Interfaces - implement interfaces

=head1 SYNOPSIS

See the synopsis of L<FP::Interface> for how to define an interface.

 {
     package Foo;
     use FP::Interfaces;

     sub foo {  }
     sub fold {  }

     FP::Interfaces::implemented qw(FP::Abstract::ExtendedSequence
                                    FP::Abstract::Pure);
 }

=head1 DESCRIPTION

This is just a wrapper around L<FP::Interface> to allow for multiple
arguments and read as proper english.

=head1 SEE ALSO

L<FP::Interface>

This implements: L<FP::Abstract::Interface>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FP::Interfaces;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use FP::Interface;

# called fully qualified, i.e. FP::Interfaces::implemented (to avoid
# namespace pollution in classes)
sub implemented {
    my $caller= [caller];
    for my $interface (@_) {
        unless (FP::Interface::package_is_populated($interface)) {
            my $subpath= $interface;
            # forever.. (how?)
            $subpath=~ s|::|/|sg;
            $subpath.= ".pm";
            require $subpath;
            #/forever
        }
        FP::Interface::implemented_with_caller($caller, $interface)
    }
}


1
