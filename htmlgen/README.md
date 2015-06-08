(Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.)

---

# Website generator from markdown files

[This](gen) is the Perl program that generates the main part of the
[functional-perl.org](http://functional-perl.org) website. It makes
use of functional-perl itself quite a bit (although it's not taking
purity very far at all), and hence might suit you as another source of
example code, but that was not its primary purpose.

## Hacking

* it takes the path to a perl file that returns a hash with
  configuration as result of its initialization. This hash is kept in
  locked state in the `$config` global variable.

* some general layout configuration can be found in `htmlgen.css`;
  this could be supplemented with other files using PXML HTML code
  returned from the function at the `head` config key (see example in
  [`gen-config`](../website/gen-config.pl)).

* the configuration for the functional-perl website chooses to put
  logo generation into its own file, [`logo.pl`](../website/logo.pl),
  so that it can be reused by the mailing list archive generator.

* `$filesinfo` (passed around explicitely for no particular reason?),
  is a `CHJ::Filesinfo` object, mutated to add information (bah, and
  that in a functional program?), maintains information about all the
  files that make up the website.

* its TEST forms are run as part of the functional-perl test suite (if
  the necessary dependencies are available)

