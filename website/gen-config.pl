use strict; use warnings FATAL => 'uninitialized';
use utf8;

use Function::Parameters qw(:strict);
our ($mydir,$gitrepository); # 'import' from main

use PXML::XHTML ":all";
use Clone 'clone';

# htmlgen is run with CWD set to website/
my $logocfg= require "./logo.pl";

my $css_path0= "FP.css";

my $version_numrevisions = lazy {
    my $describe= $gitrepository->describe ();
    my ($version,$maybe_numrevisions,$maybe_shorthash)=
      $describe=~ /^(.*?)(?:-(\d+)-g(.*))?\z/s
	or die "huh describe '$describe'";
    [$version, $maybe_numrevisions]
};

my $year= (localtime)[5]+1900;

my $email= "copying\@christianjaeger.ch"; # ? or ch@?


+{
  map_code_body=> fun ($str, $uplist, $path0) {
      my ($version, $maybe_numrevisions)= @{force $version_numrevisions};
      my $version_underscores= $version;
      $version_underscores=~ tr/./_/;
      my $commits=
	$maybe_numrevisions ?
	  ($maybe_numrevisions==1 ? "$maybe_numrevisions commit"
	   : "$maybe_numrevisions commits")
	    : "zero commits";

      $str=~ s|\$FP_VERSION\b|$version|sg;
      $str=~ s|\$FP_VERSION_UNDERSCORES\b|$version_underscores|sg;
      $str=~ s|\$FP_COMMITS_DIFFERENCE\b|$commits|sg;
      $str
  },
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
  footer=> fun ($path0) {
      my $yearstart= 2014;
      my $years= $year == $yearstart ? $year : "$yearstart-$year";
      DIV({class=>"footer_legalese"},

	  # our part
	  "© $years ",
	  A ({href=> "mailto:$email"}, "Christian Jaeger"),

	  ". ",

	  # camel logo
	  "The Perl camel image is a trademark of ",
	  A({href=> "http://www.oreilly.com"}, "O'Reilly Media, Inc."),
	  " Used with permission."
	 )
  },
  nav=>
  [
   ["README.md"],
   ["docs/howto.md"],
   ["docs/design.md"],
   ["examples/README.md"],
   ["functional_XML/README.md"],
   ["htmlgen/README.md"],
   ["docs/ideas.md"],
   ["docs/TODO.md"],
   ["COPYING.md", ["licenses/artistic_license_2.0.md"]],
  ],

  warn_hint=> 1, # warn if the website hint (header) is missing in a
                 # .md file

  downcaps=> 1, # whether to downcase all-caps filenames like README -> Readme
 }
