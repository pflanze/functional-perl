(Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.)

---

# Functional programming on Perl 5

This project aims to provide modules as well as tutorials and
introductionary materials and other knowledge to work in a functional
style on Perl.


<with_toc>

## Status: experimental

The project should not be used for production code yet for the
following reasons:

* the namespaces are not fixed yet (in particular, everything in
  `Chj::` should probably be renamed); also, the interfaces should be
  treated as alpha: this is freshly released and very much open to
  input. Some modules may be replaced with other more widely used ones
  in the interest of staying with the common base (in particular, the
  `Chj::IO::` infrastructure should likely be deprecated or
  reimplemented.) For these reasons, the modules have not been
  packaged and released on CPAN yet.

* tutorials are not complete yet, and less experienced Perl
  programmers will have difficulties writing or debugging code in this
  style on Perl without proper introduction (although, getting there)

* some problems in the perl interpreter leading to memory leaks or
  retention issues when using this style have only been fixed
  recently, and some more exotic ones are still waiting to be fixed

* some of the complications when writing functional code (as described
  in the docs of this project) might be solvable through modules or
  core interpreter changes. That would make some code easier to write
  and look at. (See [[ideas]].)

  That may also change where explicit indication about memory
  retention are still expected. (Possibly backward incompatible.)

* there are also various ways to explore performance improvements
  (read-only guarantees and caching, sequences, PXML specializations,
  implement code inlining, ...)

Please play with the examples and try to write some of your own, read
the docs and tell us what's badly explained, and if you've got
something that might be useful to add to the examples directory, it
would be cool if you offer it. If the test suite fails or you found a
bug, please tell us on the [[mailing_list]], or if you prefer submit
an issue on Github. Feel free to fork the
[repository](https://github.com/pflanze/functional-perl/) and submit
your changes on Github or to the list. Documentation improvements are
very welcome, as are general hints and ideas where to take the
project.

The project is currently led by [Christian
Jaeger](http://leafpair.com/contact). Feel free to send me private
mail if you prefer. I'm also on the `#london.pm` and
`#functional-perl` IRC channels on perl.org as "pflanze".


## Parts

* [FP::Struct](lib/FP/Struct.pm): a class generator that creates
  functional setters and takes predicate functions for type checking

* [lib/FP/](lib/FP/): library of pure functions and
  functional data structures, including various sequences (pure
  arrays, linked lists and lazy streams).

* the PXML [functional XML](functional_XML/README.md) "templating
  system" for XML based markup languages by way of Perl
  functions.

* some developer utilities: [Chj::repl](lib/Chj/repl.pm),
  [Chj::ruse](lib/Chj/ruse.pm), [Chj::Backtrace](lib/Chj/Backtrace.pm)

* [lib/Chj/IO/](lib/Chj/IO/), and its users/wrappers
  [Chj::xopen](lib/Chj/xopen.pm),
  [Chj::xopendir](lib/Chj/xopendir.pm),
  [Chj::xoutpipe](lib/Chj/xoutpipe.pm),
  [Chj::xpipe](lib/Chj/xpipe.pm),
  [Chj::xtmpfile](lib/Chj/xtmpfile.pm):
  operations on filehandles that throw exceptions on errors, plus
  many utilities.
  I wrote these around 15 years ago, as a means to offer IO with
  exceptions and more features, but in the mean time there are
  probably alternatives that are just as good or better; if you know
  which replacements I should be using, please tell.

* a few more modules that are used by the above (some originally part
  of [chj-perllib](https://github.com/pflanze/chj-perllib))

* [htmlgen](htmlgen/README.md), the tool used to generate this
  website, built on top of the above.


## Documentation

We suggest you look through the docs roughly in the given order, but
if you can't follow the presentation, skip to the intro, likewise if
you're bored skip ahead to the examples and the howto/design
documents.

### Presentation

[These](http://functional-perl.org/london.pm-talk/) are the slides of
an introductory presentation, but there's no recording and the slides
may not be saying enough for understanding. (Todo: add spoken text?)

### Intro

The [intro](intro/) directory contains scripts introducing the
concepts, including the basics of functional programming (work in
progress). The scripts are meant to be viewed in this order:

1. [basics](intro/basics)
1. [tailcalls](intro/tailcalls)
1. [more_tailcalls](intro/more_tailcalls)

This doesn't go very far yet (todo: add more).

### Examples

The [examples](examples/README.md) directory contains scripts showing
off the possibilities. You will probably not understand everything
from looking at these, but they will give an impression.

### Howto and design documents

* *[How to write functional programs on Perl 5](docs/howto.md)* is
  describing the necessary techniques to use the functional style on
  Perl. (Todo: this may be too difficult for someone who doesn't know
  anything about functional programming; what to do about it?)

* *[The design principles used in the functional-perl
  library](docs/design.md)* is descibing the organization and ideas
  behind the code that the functional-perl project offers.

### Book

If you need a more gentle introduction into the ideas behind
functional programming, you may find it in [Higher-Order
Perl](http://hop.perl.plover.com/) by Mark Jason Dominus.  This book
was written long before the functional-perl project was started, and
he does various details differently, and IIRC doesn't care about
memory retention problems (to be fair, at the time the book was
written the perl interpreter wouldn't have allowed to avoid them
anyway). (Also, IIRC he bundles lazy evaluation into the pairs;
separating these concerns should be preferable as they are then more
universally usable and combinable.) (Todo: reread book, contact
author.)


## Installation

For simplicity during development, instead of providing installer
files, the bundled scripts modify the library load path to find the
files locally. All modules are in the `lib/` directory, `use lib
$path_to_lib` is all that's needed. (Just tell if you would like
installer support. But probably, for CPAN release the project would
generate multiple packages. Are you fine with installing each part
separately even from the unified Git checkout or would you want one
single "make install"? What's the best way to achieve this?)

## Dependencies

* to run the test suite: `Test::Requires`

* to run all the tests (otherwise some are skipped):
  `BSD::Resource`, `Method::Signatures`, `Text::CSV`, `URI`

* to use `bin/repl` or the repl in the intro and examples scripts
  interactively, `Term::ReadLine::Gnu`

* to use nicer syntax for tail call optimization: `Sub::Call::Tail`


## See also

* For a real program using these modules, see
  [ml2json](http://ml2json.christianjaeger.ch).

* A [post](https://news.ycombinator.com/item?id=8734719) about streams
  in Scheme mentioning the memory retention issues that even some
  Scheme implementations can have.


</with_toc>
