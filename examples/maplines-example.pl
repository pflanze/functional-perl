use strict; use warnings; use warnings FATAL => 'uninitialized';

my $m= +{
  'ch@christianjaeger.ch'=> "Christian Jaeger",
  'foo@example.com'=> "Mr Example",
  'baz@example.com'=> undef, # drop
 };

sub {
    my ($addr)=@_;
    if (exists $$m{$addr}) {
	$$m{$addr}
    } else {
	die "unknown address: '$addr'";
    }
}
