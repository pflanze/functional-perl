#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

FP::Weak - utilities to weaken references

=head1 SYNOPSIS

 use FP::Weak;

 sub stream_foo {
     my ($s)=@_;
     weaken $_[0];
     my $f; $f= sub { ... &$f ... };
     Weakened $f
 }

 my $x = do {
     my $s= somestream;
     stream_foo (Keep $s);
     $s->first
 };

=head1 DESCRIPTION

=over 4

=item weaken <location>

Re-export of `Scalar::Util`'s `weaken`

=item Weakened <location>

Calls `weaken <location>` after copying the reference, then returns
the unweakened reference.

=item Keep <location>

Protect <location> from being weakened by accessing elements of `@_`.

=back

=cut


package FP::Weak;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(weaken Weakened Keep);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use Scalar::Util 'weaken';

# protect a variable from being pruned by callees that prune their
# arguments
sub Keep ($) {
    my ($v)=@_;
    $v
}

# weaken a variable, but also provide a non-weakened reference to its
# value as result
sub Weakened ($) {
    my ($ref)= @_;
    weaken $_[0];
    $ref
}



1
