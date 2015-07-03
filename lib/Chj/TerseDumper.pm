#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::TerseDumper

=head1 SYNOPSIS

 use Chj::TerseDumper;
 print TerseDumper($foo);

=head1 DESCRIPTION

Runs Data::Dumper's Dumper with $Data::Dumper::Terse set to 1.

=cut


package Chj::TerseDumper;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(TerseDumper);
@EXPORT_OK=qw(SortedTerseDumper);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Data::Dumper;

sub TerseDumper {
    local $Data::Dumper::Terse= 1;
    Dumper(@_)
}

sub SortedTerseDumper {
    local $Data::Dumper::Sortkeys= 1;
    TerseDumper (@_)
}


1
