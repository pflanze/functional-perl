#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Trie::t -- tests for FP::Trie

=head1 SYNOPSIS

=head1 DESCRIPTION

run by test suite

=cut


package FP::Trie::t;

use strict; use warnings FATAL => 'uninitialized';

use FP::Trie;
use FP::List qw(string_to_list);
use FP::Ops "the_method";
use Chj::TEST;

 my $t= empty_trie->set(string_to_list ("Hello"), "World");

TEST {
    [$t->perhaps_ref(string_to_list("Hell"))]
} [];

TEST {
    [$t->perhaps_ref(string_to_list("Hello"))]
} ["World"];

TEST_STDOUT {
 if (my ($subt)= $t->perhaps_skip(string_to_list("Hell"))) {
     print $subt->sublevels_length;
     if (my ($v)= $subt->perhaps_ref(string_to_list("o"))) {
         print $v;
     }
 }
}
  "1World";

TEST_STDOUT {
 if (my ($subt)= $t->perhaps_skip(string_to_list("Hello"))) {
     print $subt->sublevels_length;
     if (my ($v)= $subt->perhaps_ref(string_to_list(""))) {
         print $v;
     }
 }
}
  "0World";

TEST_STDOUT {
 if (my ($subt)= $t->perhaps_skip(string_to_list(""))) {
     print $subt->sublevels_length;
     if (my ($v)= $subt->perhaps_ref(string_to_list("Hello"))) {
         print $v;
     }
 }
}
  "1World";

my $t2= $t->update (string_to_list ("Hell"), sub {
			[@_,"yes"]
		    });
my $t3= $t2->update (string_to_list ("Hello"), sub {
			[@_,"2"]
		    });
my $t4= $t3->set (string_to_list ("Hell"), "no");

TEST {
    $t3->perhaps_ref(string_to_list "Hell")
} ["yes"];

TEST {
    $t4->perhaps_ref(string_to_list "Hell")
} "no";

TEST {
    $t4->perhaps_ref(string_to_list "Hello")
} ["World", "2"];


# keys, values

TEST {
    empty_trie ->keys->array
} [];

TEST {
    $t4->keys->map (the_method "string")->array
} ["Hell", "Hello"];

TEST {
    $t4->values->array
} ["no", ["World", "2"]];


# delete

my $t5= $t4->delete (string_to_list ("Hell"));

TEST {
    [$t5->perhaps_ref(string_to_list ("Hell"))]
} [];

TEST {
    [$t5->perhaps_ref(string_to_list ("Hello"))]
} [["World","2"]];

my $t6= $t4->delete (string_to_list ("Hello"));

TEST {
    [$t6->perhaps_ref(string_to_list ("Hell"))]
} ["no"];

TEST {
    [$t6->perhaps_ref(string_to_list ("Hello"))]
} [];

TEST {
    $t5->delete(string_to_list ("Hell")) eq $t5
} 1;

TEST_EXCEPTION {
    $t5->xdelete(string_to_list ("Hell"))
} "key not found";

# [do we want a delete_prefix method that deletes everything below
# that prefix?]


# Randomized tests for delete (too many edge cases):
sub random_key {
    my $len= int rand 4;
    join("",
	 map {
	     chr (32 + int rand 64)
	 } 1..$len)
}

use Chj::WithRepl 'withrepl';##

TEST {
    my $trie= empty_trie;
    my $hash= {};

    my $set_both= sub ($$) {
	my ($k,$i)=@_;
	$trie= $trie->set (string_to_list ($k), $i);
	$$hash{$k}=$i;
    };

    my $delete_both= sub ($) {
	my ($k)=@_;
	$trie= $trie->delete (string_to_list $k);
	delete $$hash{$k};
    };

    withrepl {
	my $oldk= random_key;
	&$set_both ($oldk, -1);

	for my $i (1..10000) {
	    my $k= random_key;
	    &$set_both ($k, $i);
	    $trie->xref (string_to_list $oldk) == $$hash{$oldk}
	      or die "bug";
	    $oldk= $k;
	  DEL: {
		my $k2= random_key;
		redo DEL if $k2 eq $oldk;
		&$delete_both ($k2);
	    }
	}

	for my $k (keys %$hash) {
	    $trie->exists (string_to_list $k)
	      or die "missing '$k' in trie";
	}

	$trie->keys->for_each
	  (sub {
	       my ($kl)=@_;
	       my $k= $kl->string;
	       exists $$hash{$k}
		 or die "key in trie that shouldn't be: '$k'";
	       delete $$hash{$k};
	   });

	keys %$hash
	  and die "keys didn't give all keys it should have";
    };
    ''
} '';


# verify that forked structures work:

my $t7= $t4->set (string_to_list("Hare"), "Krishna");

TEST {
    my ($t,$r)= $t7->skip (string_to_list("H"));
    [ $t->sublevels_length, $r ]
}
  [2, undef];

TEST {
    my ($t,$r)= $t7->skip (string_to_list("Ha"));
    [ $t->sublevels_length, $r ]
}
  [1, undef];

TEST {
    my ($t,$r)= $t7->skip (string_to_list("Hell"));
    [ $t->sublevels_length, $r ]
}
  [1, undef];

TEST {
    my ($t,$r)= $t7->skip (string_to_list("Hello"));
    [ $t->sublevels_length, $r ]
}
  [0, undef];


1