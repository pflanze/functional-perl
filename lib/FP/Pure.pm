#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Pure - base class for all purely functional data structure

=head1 SYNOPSIS

 UNIVERSAL::isa ($v, "FP::Pure") # true if $v is a purely functional DS

 # but usually:
 use FP::Predicates;
 is_pure ($v) # true if $v is (officially) immutable, detectable from
              # inheritance of FP::Pure or other means

=head1 DESCRIPTION

Base class for all data structures that don't allow mutation (by
ordinary programs), i.e. are persistent (1).

(1) as in https://en.wikipedia.org/wiki/Persistent_data_structure

=cut


package FP::Pure;

use strict; use warnings FATAL => 'uninitialized';


1
