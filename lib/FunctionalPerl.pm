#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl - functional programming on Perl

=head1 SYNOPSIS

    use FunctionalPerl;
    FunctionalPerl->VERSION # or $FunctionalPerl::VERSION

    # But all the actual modules are under FP::*, like:
    use FP::List;
    # etc.

=head1 DESCRIPTION

Allow Perl programs to be written with fewer side effects.

See the L<Functional Perl|http://functional-perl.org/> home page.

=head1 NOTE

This is alpha software! Read the package README.

=cut


package FunctionalPerl;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

our $VERSION= "0.72.6";

1
