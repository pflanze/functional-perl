#
# Copyright 2014 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FP::Hash

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FP::Hash;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(hash_set hash_delete hash_diff hashes_keys);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use Chj::TEST;

sub hash_set ($$$) {
    my ($h,$k,$v)=@_;
    my $h2= +{%$h};
    $$h2{$k}=$v;
    $h2
}

TEST { my $h= {a=>1, b=>2}; hash_set $h, b=>3 }
+{
    'a' => 1,
    'b' => 3
};
TEST { my $h= {a=>1, b=>2}; hash_set $h, b=>3; $h }
+{
    'a' => 1,
    'b' => 2
};

sub hash_delete ($$) {
    my ($h,$k)=@_;
    my $h2= +{%$h};
    delete $$h2{$k};
    $h2
}



# looking for definedness, not exists. Ok? Also, only handles strings
# as values.
sub hash_diff ($$) {
    my ($h1,$h2)=@_;
    my $changes={};
    for my $key (keys %$h2) {
	my $old= $$h1{$key};
	my $new= $$h2{$key};
	if (defined ($old) and defined ($new)) {
	    $$changes{$key}= ($old eq $new) ? "unchanged" : "changed";
	} else {
	    $$changes{$key}= defined ($old) ? "deleted" : "added";
	}
    }
    for my $key (keys %$h1) {
	next if defined $$h2{$key};
	$$changes{$key}= "deleted";
    }
    $changes
}

TEST {hash_diff {a=>1,b=>2}, {a=>1,b=>3}}
+{
    'a' => 'unchanged',
    'b' => 'changed'
};
TEST {hash_diff {a=>1,b=>2}, {a=>1,b=>3,c=>5}}
+{
    'c' => 'added',
    'a' => 'unchanged',
    'b' => 'changed'
};
TEST {hash_diff {a=>1,b=>2}, {b=>3,c=>5}}
+{
    'c' => 'added',
    'a' => 'deleted',
    'b' => 'changed'
};
TEST {hash_diff {a=>1,b=>2,x=>9}, {a=>undef,b=>3,c=>5,x=>9}}
+{
    'c' => 'added',
    'a' => 'deleted',
    'b' => 'changed',
    'x' => 'unchanged'
};

use Chj::FP::HashSet;

sub hashes_keys {
    keys %{array2hashset( [map { keys %$_ } @_] )}
}


1
