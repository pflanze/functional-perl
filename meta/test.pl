our $len;

sub readin {
    my ($what, $maybe_on_error)=@_;
    my $default_on_error = sub {
	warn "$what: $! exit value: $?";
	undef
    };
    my $on_error= $maybe_on_error // $default_on_error;
    open my $in, $what
      or die "$what: $!";
    my $rv=read $in, my ($buf), $len//999999;
    defined $rv
      or die $!;
    if (defined $len) {
	$rv == $len or die "only got $rv bytes instead of $len";
    }
    close $in ? $buf
      : &$on_error($buf, $default_on_error, $!, $?)
}

1
