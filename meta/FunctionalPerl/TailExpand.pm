#
# Copyright (c) 2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::TailExpand

=head1 SYNOPSIS

    use lib "./meta";
    use FunctionalPerl::TailExpand;
    use FunctionalPerl::Htmlgen::Nav; # or whatever other modules use tail

=head1 DESCRIPTION

Avoid dependency on L<Sub::Call::Tail> by running C<bin/expand-tail>
on all modules (that can contain C<tail> calls) first.

Automatically runs C<use lib "./.htmlgen";> etc. to have subsequent
module loads happen from the expanded files.

Can only be run with the current working directory being the root of
the source repository, i.e. during testing (or build).

=cut


package FunctionalPerl::TailExpand;
#@ISA="Exporter"; require Exporter;
#@EXPORT=qw();
#@EXPORT_OK=qw();
#%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use lib "./lib";
use Chj::xperlfunc ":all";

xxsystem_safe $^X, "meta/tail-expand";

use lib "./.htmlgen";

# no need; XX skip in meta/tail-expand
# use lib "./.lib";
# use lib "./.meta";

# normal load paths, to be transparent re what should be loaded
# use lib "./meta"; no need as that had to be done already to reach us


1
