Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

# A website generator from markdown files

[This](gen) is the Perl program that generates most of the
[functional-perl.org](http://functional-perl.org) website. It makes
use of functional-perl itself quite a bit, although it was originally
written for practical purposes, not as a demo. (Todo: make it nicer?)

The code that builds the table of content, `map_with_toc`, is purely
functional. It uses a variant of `fold_right` that also explicitely
passes state while recursing down the input lists (the HTML (which is
parsed to `PXML`) element bodies), which allows to collect the
subsection headers (which don't need to reside within in the same HTML
element) and get the numbering while mapping the HTML document to add
the numbering at the same time. This code may look a bit involved, and
could perhaps be abstracted into some PXML library functions (how
would XSLT look to do the same?).

`map_with_toc` is called from `process_body`, which uses
`pxml_map_elements` from `PXML::Util` to map various HTML
elements. Mapper functions receive the element and an "uplist", which
is a linked list with the parents (with the direct one being the
head). Note that purely functional data structures can't store links
to parents in their elements (unless when cheating by way of
recreating the parents on the fly or referring to them lazily); thus
the mappers wouldn't know the context. But we can instead pass the
context when those functions are actually called (which in typical
functional manner is better since the same subtree can now be part of
various different parents at the same time).

The `htmlgen/` directory contains the universally usable program,
whereas the `website/` directory contains the configuration to build
the functional-perl website.

Note that the first time you run it, it will test everything that is
quoted and looks like a namespace on metacpan to see whether it's a
module, which takes time and can fail with network or server errors;
the results are cached, thus subsequent runs will be fast.

## Formatting

The *.md files support standard Markdown format plus the following
additions:

 - files are expected to carry a header similar to

        "Check the [Foo website](http://foo.org/) for
        properly formatted versions of these documents.

        ---
        "

   which is stripped from the file

 - local urls starting with // are resolved to the path where the file
    with the given filename resides. Example:

         [a thing](//some_thing.md)

   is being resolved to something like

         <a href="../bar/some_thing.xhtml">a thing</a>

 - wiki style links like:

        [[some_thing]]

   or

        [[some_thing|a thing]]

   are supported, converting to

         <a href="../bar/some_thing.xhtml">some thing</a>

   or

         <a href="../bar/some_thing.xhtml">a thing</a>

   respectively.


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

* the word "path0" in identifier names refers to a relative path from
  the site root.

* `$filesinfo` (passed around explicitely for no particular reason?),
  is a `PFLANZE::Filesinfo` object, mutated to add information
  (remember that I said it was not meant as a functional programming
  demo), maintains information about all the files that make up the website.
  Likewise, `$genfilestate` is a `PFLANZE::Genfilestate` object, which
  also contains the former.

* its TEST forms are run as [part of the functional-perl test
  suite](../t/htmlgen) (if the necessary dependencies are available)

