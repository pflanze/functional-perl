our $len;

sub readin {
    my ($what)=@_;
    open my $in, $what
      or die "$what: $!";
    my $rv=read $in, my ($buf), $len//999999;
    defined $rv
      or die $!;
    if (defined $len) {
	$rv == $len or die "only got $rv bytes instead of $len";
    }
    close $in ? $buf
      : do {
	  warn "$what: $! exit value: $?";
	  undef
      }
}

1
