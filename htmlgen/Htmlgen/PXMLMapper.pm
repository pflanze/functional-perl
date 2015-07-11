#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Htmlgen::PXMLMapper - base class for PXML mappers

=head1 SYNOPSIS

=head1 DESCRIPTION

Holding context that may be needed by mapping functions that change
the PXML representing a page in htmlgen.

=cut


package Htmlgen::PXMLMapper;

use strict; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
use Sub::Call::Tail;

use FP::Predicates;

use FP::Struct [
		[*is_nonnullstring, "path0"],
		[*is_procedure, "maybe_have_path0"],
		[maybe(*is_procedure), "map_code_body"],
	       ];

method match_element_names ()
  { die "need implementation that returns an element name" }


_END_
