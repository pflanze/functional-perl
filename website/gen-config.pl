use strict; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
our $mydir; # 'import' from main

use PXML::XHTML ":all";
use Clone 'clone';

my $logocfg= require "./logo.pl";
my $my_css_path= "FP.css";

+{
  copy_paths=>
  [
   "FP-logo.png",
   "FP.css",
  ],
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
      # HTML to add to the <head> section
      LINK ({rel=> "stylesheet",
	     href=> url_diff ($path0, $my_css_path),
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
docs/howto_and_comparison_to_Scheme.md
docs/ideas.md
examples/README.md
ftemplate/README.md
    )],

  warn_hint=> 1, # warn if the website hint (header) is missing in a
                 # .md file

  downcaps=> 1, # whether to downcase all-caps filenames like README -> Readme
 }
