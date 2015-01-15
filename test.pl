our $len;

sub readin {
    my ($what)=@_;
    open my $in, $what
      or die "$what: $!";
    my $rv=read $in, my ($buf), $len;
    defined $rv or die $!;
    $rv == $len or die "only got $rv bytes instead of $len";
    close $in; # or die $!;
    $buf
}

