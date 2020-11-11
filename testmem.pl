use Test::Requires qw(BSD::Resource);
import BSD::Resource;

sub MB ($) {
    $_[0]* 1048576
}

my $RLIMIT_KIND =
    # At least OpenBSD does not have RLIMIT_VMEM; RLIMIT_DATA is the
    # memory limit it supports. Linux does, too, so just use that one
    RLIMIT_DATA;
    
sub setlimit_mem_MB ($) {
    my ($limit_MB) = @_;
    my $limit = MB $limit_MB;
    setrlimit $RLIMIT_KIND, $limit, $limit
      or die "setrlimit: $!";
}

1
