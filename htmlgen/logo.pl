use strict; use warnings FATAL => 'uninitialized';
use Chj::PXHTML ":all";

my $homeurl= "http://ml2json.christianjaeger.ch";

+{
  homeurl=> $homeurl,
  logo=> DIV ({class=> "header"},
	      A({href=> "$homeurl", class=> "header"},
		SPAN({class=> "logo1"}, "ml2json"),
		SPAN({class=> "logo2"}, " mail archive processor"))),
 }
