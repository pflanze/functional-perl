#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::PClosure

=head1 SYNOPSIS

 use Chj::PClosure;

 sub handler {
    my ($v1,$v2,$v3)=@_;
    [$v1,$v2,$v3]
 }

 my $cl= PClosure (*handler, "a", "b");
 # serialize, deserialize,
 $cl->call("c"); # -> ["a","b","c"]
 # or pass $cl to Chj::Parallel::Instance's stream_for_each method etc.

=head1 DESCRIPTION

Constructor for a Chj::Parallel::Closure object; may 'PClosure' stand
for 'pseudo closure', or 'Chj::Parallel::Closure'.

=cut


package Chj::PClosure;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(PClosure);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::Parallel::Closure;
use Chj::TEST;

sub PClosure {
    my ($procglob,@envvals)=@_;
    ref (\$procglob) eq "GLOB" or die "expecting a GLOB as first argument";
    Chj::Parallel::Closure->new(substr("$procglob",1),\@envvals);
}

sub t {
    [@_]
}
TEST { PClosure(*t,"a","b")->call("c") } ["a","b","c"];

1
