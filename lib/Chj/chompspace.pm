# Copyright 2004 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::chompspace

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::chompspace;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(chompspace);
#@EXPORT_OK=qw();
use strict;

sub chompspace($) {
    my ($str)=@_;
    $str=~ s/^\s+//s;
    $str=~ s/\s+\z//s;
    $str
}

*Chj::chompspace= \&chompspace;

1;
