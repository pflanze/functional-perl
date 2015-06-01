use strict; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
our $mydir; # 'import' from main

my $usageanchor= 'Run `./ml2json --help`.';
use Chj::xpipe;
sub helptext {
    my ($path,$path0)=@_;
    ## (ugly again)
    my $diff= substr ($path, 0, length ($path) - length( $path0));
    my ($r,$w)= xpipe;
    if (xfork) {
	$w->xclose;
	my $str=$r->xcontent;
	xwait;
	warn "error in subprocess, exit code $?, output: $str "
	    unless $? == 0;
	$str
    } else {
	$r->xclose;
	local $ENV{ML2JSON_MYDIR}=".";
	open STDOUT, ">&".fileno($w) or die $!;
	open STDERR, ">&".fileno($w) or die $!;
	xchdir $diff if length $diff;
	xexec "./ml2json","--help";
    }
}

use Chj::PXHTML ":all";

my $logocfg= require "$mydir/logo.pl";

+{
  indexpath0P=> fun ($path0) {
      # only handle the toplevel README.md file as index file for its
      # dir:
      $path0 eq "README.md"
  },
  path0_handlers=>
  +{
    "docs/usage.md"=> fun ($path,$path0,$str) {
	$str=~ s{\Q$usageanchor}{
	    my $str= helptext($path,$path0);
	    $str=~ s/^/    /mg;
	    ("Skip to [instructions](#Instructions) below to see a recipe.\n\n".
	     "    \$ ./ml2json --help\n".
	     $str)
	}e or warn "no match";
	$str
    }
   },
  title=> fun ($filetitle) {
      ($filetitle, " - ml2json")
  },
  head=> fun ($path0) {
      # HTML before navigation
      $$logocfg{logo}
  },
  belownav=> fun ($path0) {
      # HTML between navigation and page content
      undef
  },
  sortorder=>
  [qw(
	 README.md
	 INSTALL.md
	 docs/usage.md
	 docs/phases.md
	 docs/message_identification.md
	 docs/warnings.md
	 TODO.md
	 docs/hacking.md
	 docs/mbox.md
	 COPYING.md
	 CONTACT.md
	 docs/mailing_list.md
    )],

  warn_hint=> 1, # warn if the website hint (header) is missing in a
                 # .md file

  downcaps=> 1, # whether to downcase all-caps filenames like README -> Readme
 }
