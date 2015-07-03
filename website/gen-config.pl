use strict; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
our $mydir; # 'import' from main

use PXML::XHTML ":all";
use Clone 'clone';

# htmlgen is run with CWD set to website/
my $logocfg= require "./logo.pl";

my $css_path0= "FP.css";

+{
  #copy_paths=> [], optional, for path0s from the main source root
  copy_paths_separate=>
  # source_root => path0s
  +{"."=> [
	   "FP-logo.png",
	   $css_path0,
	  ]},
  path0_handlers=>
  +{
   },
  title=> fun ($filetitle) {
      ($filetitle, " - functional-perl.org")
  },
  head=> fun ($path0) {
      # HTML to add to the <head> section
      LINK ({rel=> "stylesheet",
	     href=> url_diff ($path0, $css_path0),
	     type=> "text/css"})
  },
  header=> fun ($path0) {
      # HTML above navigation

      # XX hack: clone it so that serialization doesn't kill parts of
      # it (by way of `weaken`ing)
      clone $logocfg->($path0)->{logo}
  },
  belownav=> fun ($path0) {
      # HTML between navigation and page content
      ()
  },
  sortorder=>
  [qw(
README.md
docs/howto.md
docs/design.md
examples/README.md
functional_XML/README.md
htmlgen/README.md
docs/ideas.md
docs/TODO.md
    )],

  warn_hint=> 1, # warn if the website hint (header) is missing in a
                 # .md file

  downcaps=> 1, # whether to downcase all-caps filenames like README -> Readme
 }
