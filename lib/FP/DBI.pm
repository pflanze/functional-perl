#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
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
 my $s1= $sth->array_stream; # arrays
 # or
 my $s2= $sth->hash_stream;  # hashes

 use PXML::XHTML;
 TABLE
   (TH($s->first->map (*TD)),
    $s->rest->take (10)->map (sub {TR($_[0]->map (*TD))}))

=head1 DESCRIPTION

Get rows as items in a lazy linked list (functional stream).

=head1 SEE ALSO

L<DBI>, L<FP::Stream>

=cut


package FP::DBI;

use strict; use warnings FATAL => 'uninitialized';

use DBI;
use Chj::TEST;

use Chj::NamespaceCleanAbove;

{
    package FP::DBI::db;
    our @ISA= 'DBI::db';
    # what for? DBI warns otherwise.
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

    # XX there should already be code like this in IOStream.pm?
    sub make_X_stream {
	my ($method)=@_;
	sub {
	    my $s=shift;
	    my $lp; $lp= sub {
		lazy {
		    if (my $v= $s->$method) {
			cons $v, &$lp;
		    } else {
			null
		    }
		}
	    };
	    Weakened ($lp)->()
	}
    }

    use Chj::NamespaceCleanAbove;

    sub row_stream {
	my $s=shift;
	my $lp; $lp= sub {
	    lazy {
		#bless $s->fetchrow_arrayref, "FP::DBI::Row"  nope, readonly
		if (my @r= $s->fetchrow_array) {
		    cons bless (\@r, "FP::DBI::Row"), &$lp;
		} else {
		    null
		}
	    }
	};
	Weakened ($lp)->()
    }

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
