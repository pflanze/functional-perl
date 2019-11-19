#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Repl::Dependencies - hack to load Repl dependencies

=head1 SYNOPSIS

 use Chj::TEST use=> 'FP::Repl::Dependencies';

=head1 DESCRIPTION

Term::ReadLine::Gnu does not allow to check for its presence
directly. When require'ing Term::ReadLine::Gnu, it gives an error
saying "It is invalid to load Term::ReadLine::Gnu directly.". That
makes it appear as unloadable when in fact it is present. And
depending on just Term::ReadLine is not enough, the repl will then
fail at runtime. Stupid.

So, this.

=cut


package FP::Repl::Dependencies;
#@ISA="Exporter"; require Exporter;
#@EXPORT=qw();
#@EXPORT_OK=qw();
#%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';


use Term::ReadLine;

$Term::ReadLine::Gnu::VERSION
  or die "dependency Term::ReadLine::Gnu not present";

# now also depend on PadWalker etc.
require FP::Repl::Repl;

1
