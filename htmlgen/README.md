(Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.)

---

# A website generator from markdown files

[This](gen) is the Perl program that generates most of the
[functional-perl.org](http://functional-perl.org) website. It makes
use of functional-perl itself quite a bit, although it was originally
written for practical purposes, not as a demo. (Todo: make it nicer?)

The code that builds the table of content is purely functional. It
uses a variant of `fold_right` that also explicitely passes state
while recursing down the input lists (the HTML (which is parsed to
`PXML`) element bodies), which allows to collect the subsection
headers (which don't need to reside within in the same HTML element)
and get the numbering while mapping the HTML document to add the
numbering at the same time. This code may look a bit involved, and
could perhaps be abstracted into some PXML library functions (how
would XSLT look to do the same?).

The `htmlgen/` directory contains the universally usable program,
whereas the `website/` directory contains the configuration to build
the functional-perl website.


## Hacking

* to work interactively with the code, run `website/gen-repl`

* it takes the path to a perl file that returns a hash with
  configuration as result of its initialization. This hash is kept in
  locked state in the `$config` global variable.

* some general layout configuration can be found in `htmlgen.css`;
  this could be supplemented with other files using PXML HTML code
  returned from the function at the `head` config key (see example in
  [`gen-config.pl`](../website/gen-config.pl)).

* the configuration for the functional-perl website chooses to put
  logo generation into its own file, [`logo.pl`](../website/logo.pl),
  so that it can be reused by the mailing list archive generator.

* `$filesinfo` (passed around explicitely for no particular reason?),
  is a `PFLANZE::Filesinfo` object, mutated to add information
  (remember that I said it was not meant as a functional programming
  demo), maintains information about all the files that make up the website.

* its TEST forms are run as [part of the functional-perl test
  suite](../t/htmlgen) (if the necessary dependencies are available)

