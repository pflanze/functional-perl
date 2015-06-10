#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

FP::Trampoline -- tail call optimization without reliance on goto

=head1 SYNOPSIS

 use FP::Trampoline; # exports `T` and `trampoline`

 sub iterative_fact {
     my ($n,$tot)= @_;
     $n > 1 ? T{ iterative_fact ($n-1, $tot*$n) } : $tot
 }
 sub fact {
     my ($n)=@_;
     trampoline iterative_fact ($n, 1)
 }

=head1 DESCRIPTION

Perl has direct support for optimized (i.e. non-stack-eating) tail
calls, by way of `goto $subref`, but there are still bugs in current
versions of Perl with regards to memory handling in certain situations
(see L<t/perl/goto-leak>). Trampolining is a technique that works
without reliance on any tail call optimization support by the host
language. Its drawbacks are more overhead and the requirement to put a
`trampoline`ing call around any function that employs trampolining.

=head1 FUNCTIONS

=item T { ... }

Returns a closure blessed into the `FP::Trampoline` namespace,
which represents a trampolining continuation.

=item trampoline ($value)

The trampoline that bounces back as long as need be: if $value is
blessed into the `FP::Trampoline` namespace, it is called and the
result fed back into `trampoline`, otherwise it is returned directly.

=cut


package FP::Trampoline;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(T trampoline);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

sub T (&) {
    bless $_[0], __PACKAGE__
}

sub trampoline ($) {
    my ($v)=@_;
    while (ref ($v) eq __PACKAGE__) {
	$v=&$v()
    }
    $v
}

1
