use Test::Requires qw(BSD::Resource);
import BSD::Resource;

sub MB ($) {
    $_[0]* 1048576
}

my $RLIMIT_KIND=
    # At least OpenBSD does not have RLIMIT_VMEM:
    $^O =~ /bsd/i ? RLIMIT_DATA() # openbsd, freebsd, netbsd?
    # others, including Linux:
    : RLIMIT_VMEM();
    
sub setlimit_mem_MB ($) {
    my ($limit_MB)=@_;
    my $limit= MB $limit_MB;
    setrlimit $RLIMIT_KIND, $limit, $limit
      or die "setrlimit: $!";
}

1
