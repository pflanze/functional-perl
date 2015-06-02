use strict; use warnings FATAL => 'uninitialized';
use PXML::XHTML ":all";

my $homeurl= "http://functional-perl.org";

+{
  homeurl=> $homeurl,
  logo=> DIV ({class=> "header"},
	      A({href=> "$homeurl", class=> "header"},
		SPAN({class=> "logo1"}, "Functional Perl"),
		SPAN({class=> "logo2"}, " programming project"))),
 }
