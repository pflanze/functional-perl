#
# Copyright 2014-2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

FP::Hash

=head1 SYNOPSIS

 use FP::Hash;

 my $a= {a=>1, b=>2};
 my $b= hash_set($a, "b", 3);
 my $c= hash_delete($b, "a");
 if (my ($v)= hash_perhaps_ref ($c, "x")) {
    ...
 }

 print Dumper($c); # {b => 3}
 print Dumper($a); # {a => 1, b => 2}

=head1 DESCRIPTION

Provides pure functions on hash tables. Note though that hash table
updates simply copy the whole hash table, thus you may easily get bad
computational complexity. (If you really care about that, and not so
much about interoperability with other Perl code, perhaps port a
functional hash tables implementation (like the one used by Clojure)?)


=cut


package FP::Hash;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(hash_set hash_perhaps_ref hash_xref
	   hash_delete hash_diff hashes_keys $empty_hash);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Chj::TEST;

#use Const::Fast;
#const my %empty_hash;

# since Const::Fast doesn't (currently) buy anything more than
# Hash::Util's lock_hash, use the latter for less dependencies.
use Hash::Util 'lock_hash';
my %empty_hash;
lock_hash %empty_hash;

our $empty_hash= \%empty_hash;

#TEST_EXCEPTION { $$empty_hash{a} }
#  undef;
#
# Aw, that also gives 'Attempt to access disallowed key \'a\' in a
# restricted hash'.  man Const::Fast says: "You have to use exists
# $a{baz} instead. This is a limitation of perl that can hopefully be
# solved in the future."

TEST_EXCEPTION { $$empty_hash{a} = 1 }
  'Attempt to access disallowed key \'a\' in a restricted hash';

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

# should in principle be called hash_perhaps_ref ?
sub hash_perhaps_ref ($$) {
    my ($h,$k)=@_;
    if (exists $$h{$k}) {
	$$h{$k}
    } else {
	()
    }
}

sub hash_xref ($$) {
    my ($h,$k)=@_;
    if (exists $$h{$k}) {
	$$h{$k}
    } else {
	die "unbound table key"; # no such key. unknown key. unbound
                                 # hash key. ?
    }
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

use FP::HashSet;

sub hashes_keys {
    keys %{array2hashset( [map { keys %$_ } @_] )}
}


1
