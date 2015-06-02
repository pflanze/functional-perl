use strict; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
our $mydir; # 'import' from main

use PXML::XHTML ":all";

my $logocfg= require "$mydir/logo.pl";

+{
  indexpath0P=> fun ($path0) {
      # only handle the toplevel README.md file as index file for its
      # dir:
      $path0 eq "README.md"
  },
  path0_handlers=>
  +{
   },
  title=> fun ($filetitle) {
      ($filetitle, " - functional-perl.org")
  },
  head=> fun ($path0) {
      # HTML above navigation
      $$logocfg{logo}
  },
  belownav=> fun ($path0) {
      # HTML between navigation and page content
      undef
  },
  sortorder=>
  [qw(
README.md
docs/howto_and_comparison_to_Scheme.md
docs/ideas.md
examples/README.md
ftemplate/README.md
    )],

  warn_hint=> 1, # warn if the website hint (header) is missing in a
                 # .md file

  downcaps=> 1, # whether to downcase all-caps filenames like README -> Readme
 }
