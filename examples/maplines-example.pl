use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use FP::Array_sort qw(on);
use FP::Ops qw(string_lc string_cmp);

my $m = +{
    'ch@christianjaeger.ch' => "Christian Jaeger",
    'foo@example.com'       => "Mr Example",
    'baz@example.com'       => undef,                # drop
};

+{
    map => sub {
        my ($addr) = @_;
        if (exists $$m{$addr}) {
            $$m{$addr}
        } else {
            die "unknown address: '$addr'";
        }
    },
    cmp => on(\&string_lc, \&string_cmp),
    }
