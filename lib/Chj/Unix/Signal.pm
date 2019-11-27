#
# Copyright (c) 2007 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::Unix::Signal

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package Chj::Unix::Signal;

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Chj::Class::Array -fields=>
  -publica=>
  'number',
  ;


sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    ($$s[Number])=@_;
    $s
}

# how do we do reverse mapping? I did it already somewhere, I know.
# and /bin/kill doesn't know all of them, bush eh bash is much better.
# ah, man perlipc "Signals":

our $inited=0;
our $signo;
our $signame;
sub MaybeInit {
    $inited ||= do {
        require Config;
        my $cfg= $Config::Config{sig_name};
        defined $cfg or die "No sigs?";
        my $i=0;
        foreach my $name (split(' ', $cfg)) {
            $$signo{$name}= $i;
            $$signame[$i]= $name;
            $i++
        }
        1
    }
}

sub as_string {
    my $s=shift;
    MaybeInit;
    my $maybe_str= $$signame[$$s[Number]];
    defined $maybe_str ? $maybe_str : "<unknown signal (number $$s[Number])>"
}

end Chj::Class::Array;
