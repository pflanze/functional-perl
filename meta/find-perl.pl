require "./meta/test.pl";

my $path = $^X;

if ($path =~ s{[\\/]perl[^\\/]*\z}{}s) {
    $ENV{PATH} = "$path:$ENV{PATH}";
}
else {
    warn "no match for perl in '$path'";
}

