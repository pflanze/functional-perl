use Test::Requires qw(BSD::Resource);
import BSD::Resource;

sub MB ($) {
    $_[0]* 1048576
}

sub setlimit_mem_MB ($) {
    my ($limit_MB)=@_;
    my $limit= MB $limit_MB;
    setrlimit RLIMIT_VMEM, $limit, $limit
      or die "setrlimit: $!";
}

1
