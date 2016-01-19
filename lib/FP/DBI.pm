#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::DBI - DBI with results as lazy lists

=head1 SYNOPSIS

 use FP::DBI;

 $dbh = FP::DBI->connect($data_source, $username, $auth, \%attr);

 # same as `DBI`:
 ..
 $sth = $dbh->prepare($statement);
 ..
 $rv = $sth->execute;

 # then:
 my $s= $sth->row_stream;    # purearrays blessed to FP::DBI::Row
 # or
 #my $s= $sth->array_stream; # arrays
 # or
 #my $s= $sth->hash_stream;  # hashes

 use PXML::XHTML;
 TABLE
   (TH($s->first->map (*TD)),
    $s->rest->take (10)->map (sub {TR($_[0]->map (*TD))}))

=head1 DESCRIPTION

Get rows as items in a lazy linked list (functional stream).

NOTE: `DBI` is designed so that when running another `execute` on the
same statement handle, fetching returns rows for the new execute; this
means, a new execute makes it impossible to retrieve further results
from the previous one. Thus if a result stream isn't fully used before
a new `execute` or a different result request is being made, then the
original stream can't be further evaluated anymore; to prevent this
from happening, an interlock mechanism is built in that throws an
error in this case.


=head1 SEE ALSO

L<DBI>, L<FP::Stream>

=cut


package FP::DBI;

use strict; use warnings; use warnings FATAL => 'uninitialized';

use DBI;
use Chj::TEST;

use Chj::NamespaceCleanAbove;

{
    package FP::DBI::db;
    our @ISA= 'DBI::db';

    sub prepare {
	my $s=shift;
	my $st= $s->SUPER::prepare(@_);
	bless $st, "FP::DBI::st"
    }
}

{
    package FP::DBI::Row;
    use base 'FP::PureArray';
}

{
    package FP::DBI::st;
    our @ISA= 'DBI::st';
    use FP::Lazy;
    use FP::Weak;
    use FP::List;

    sub make_X_stream {
	my ($method, $maybe_mapfn)=@_;
	sub {
	    my $s=shift;
	    my $id= ++$$s{fp__dbi__id};
	    my $lp; $lp= sub {
		my $lp=$lp; #keep strong reference
		lazy {
		    # XXX: some bug leads to both values being undef
		    # now [when using SQLite] (it's not the Weakened)
		    if (defined $id and defined $$s{fp__dbi__id}) {
			$$s{fp__dbi__id} == $id
			  or die ("stream was interrupted by another execute".
				  " or stream request");
		    } else {
			#warn "undef value hu";
		    }
		    if (my $v= $s->$method) {
			cons ($maybe_mapfn ? &$maybe_mapfn($v) : $v, &$lp);
		    } else {
			null
		    }
		}
	    };
	    Weakened ($lp)->()
	}
    }

    use Chj::NamespaceCleanAbove;


    sub execute {
	my $s=shift;
	$$s{fp__dbi__id}++;
	$s->SUPER::execute (@_)
    }

    *row_stream= make_X_stream ("fetchrow_arrayref",
				sub {
				    bless ([ @{$_[0]} ], "FP::DBI::Row")
				});
    *array_stream= make_X_stream ("fetchrow_arrayref");
    *hash_stream= make_X_stream ("fetchrow_hashref");

    _END_
}


use base 'DBI';

sub connect {
    my $cl=shift;
    my $v= $cl->SUPER::connect (@_);
    bless $v, "FP::DBI::db"
}


_END_ # namespace cleaning
