#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Abstract::Pure - functional purity protocol

=head1 SYNOPSIS

 UNIVERSAL::isa ($v, "FP::Abstract::Pure") # true if $v is a purely functional DS

 # but usually:
 use FP::Predicates;
 is_pure ($v) # true if $v is (officially) immutable, detectable from
              # inheritance of FP::Abstract::Pure or other means

=head1 DESCRIPTION

Base class for all data structures that don't allow mutation (by
ordinary programs), i.e. are persistent (1).

(1) as in https://en.wikipedia.org/wiki/Persistent_data_structure

More precisely, those objects that don't have methods that when called
make other methods non-functions.

=cut


package FP::Abstract::Pure;

use strict; use warnings; use warnings FATAL => 'uninitialized';


1
