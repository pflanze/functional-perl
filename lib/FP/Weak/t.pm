#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

FP::Weak::t - tests for FP::Weak

=head1 SYNOPSIS

 # just let it sit there and be tested by `t/require_and_run_tests`

=head1 DESCRIPTION


=cut


package FP::Weak::t;

use strict; use warnings FATAL => 'uninitialized';

use FP::Weak ":all";
use Chj::TEST;

sub t {
    my $foo= []; weaken $foo; $foo
}

TEST { my $foo= []; noweaken $foo; $foo }
  [];
TEST { t }
  undef;
TEST { with_noweaken { t } }
  [];
TEST { &with_noweaken (*t) }
  [];
TEST { t }
  undef;
TEST {
    my @w;
    local $SIG{__WARN__}= sub {
	my ($msg)= @_;
	$msg=~ s/0x[0-9a-f]*/0x.../s;
	$msg=~ s/ at .*/ .../s;
	push @w, $msg
    };
    [ &with_warnweaken (*t), @w]
}
  [undef, "weaken (ARRAY(0x...)) ..."];

1
