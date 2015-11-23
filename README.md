Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

# Functional programming on Perl (5)

This project aims to provide modules as well as tutorials and
introductionary materials and other knowledge to work in a functional
style on Perl. Currently the focus is on getting it to work well for
programs on Perl 5. We'd appreciate discussing and collaborating with
people working on Perl 6 now already, though, so as to adapt where
useful.


<with_toc>

## Teaser

This is an example of the kind of code we want to make possible:

    use PXML::Tags qw(myexample protocol-version records record a b c d);

    print RECORD(A("hi"),B("there"))->string; 
    # prints: <record><a>hi</a><b>there</b></record>

    # Now create a bigger document, with its inner parts built from
    # external inputs:
    MYEXAMPLE
      (PROTOCOL_VERSION ("0.123"),
       RECORDS
       (csv_file_to_rows($inpath, {eol=> "\n", sep_char=> ";"})
        # skip the header row
        ->rest
        # map rows to XML elements
        ->map(sub {
                  my ($a,$b,$c,$d)= @{$_[0]};
                  RECORD A($a), B($b), C($c), D($d)
              })))
      # print data structure to disk, forcing its evaluation as needed
      ->xmlfile($outpath);

    # Note that the above document is built lazily: `csv_file_to_rows`
    # returns a *lazy* list of rows, which means the rows will only be
    # read from disk once `xmlfile` runs and requests each
    # XML-formatted row in turn while it prints the document as a
    # string to the out file.

See [examples/csv_to_xml_short](examples/csv_to_xml_short) for the
complete script, and the [examples](examples/README.md) page for more.

Note that the above example merely shows the use of (lazy)
sequences. But functional programming is the paradigm that was used to
implement them. The example actually isn't strictly purely functional,
as it reads from and writes to files, which makes it carry out, or be
exposed to, side effects; see
[[howto#Pure_functions_versus_I/O_and_other_side-effects]] for a
discussion about this.

If you'd just like to see a practical introduction, read the
[[intro]].


## Status: experimental

There are several reasons that this project should be considered
experimental at this time:

* some problems in the perl interpreter (leading to memory retention
  issues) when using this style have only been fixed recently, and
  some more exotic ones are still waiting to be examined.

* the author of the current code in this project has taken many
  liberties to reimplement functionality that exists elsewhere on CPAN
  already, partly out of interest in figuring out the best way to do
  things on base principles, partly because of a lack of knowledge of
  the latest trents in the Perl world (he programmed primarily in
  Scheme for the last 8 years). For example to provide for objects
  with purely functional updates, he chose to write the class
  generator `FP::Struct` and based its type checking approach on
  predicate functions instead of trying to extend Moose or one of its
  alternatives: it was easy to do, nicely small and clean, and allowed
  to play with the approach. But there's no need that this stays, work
  or suggestions on how to move to an approach using Moose or
  something else are very welcome. Similarly, the `Chj::IO::`
  infrastructure should most probably be removed and the missing bits
  added to existing commonly used modules.

* the namespaces are not fixed yet (in particular, everything in
  `Chj::` should probably be renamed); also, the interfaces should be
  treated as alpha: this is freshly released and very much open to
  input. For these reasons, the modules have not been packaged and
  released on CPAN yet.

* some of the complications when writing functional code (as described
  in the [[howto]]) might be solvable through modules or core
  interpreter changes. That would make some code easier to write and
  look at. (See [[ideas]].) This may then also change where explicit
  indication about memory retention are still expected (possibly
  even in backwards incompatible ways.)

* various parts (filesystem accesses etc.) probably won't work on
  Microsoft Windows yet

The plan is to accept compatibility-breaking changes until February
2016, then make a stable release in April 2016. If you'd like to get a
maintained and versioned release earlier, please say so.

[I](//contact.md)'m using it already in personal projects; where
breakage due to changes is unacceptable, I currently add
functional-perl as a Git submodule to the project using it and `use
lib` it from the actual project.


## Parts

* `FP::Struct`: a class generator that creates
  functional setters and accepts predicate functions for type checking
  (for the reasoning see the [[howto#Object_oriented_functional_programming]])

* [lib/FP/](lib/FP/): a library of pure functions and
  functional data structures, including various sequences (pure
  arrays, linked lists and lazy streams).

* the "PXML" [functional XML](functional_XML/README.md) "templating
  system" for XML based markup languages by way of Perl
  functions.

* some developer utilities: `Chj::repl`, `Chj::ruse`, `Chj::Backtrace`,
  `Chj::Trapl`.

* [lib/Chj/IO/](lib/Chj/IO/), and its users/wrappers
  `Chj::xopen`,
  `Chj::xopendir`,
  `Chj::xoutpipe`,
  `Chj::xpipe`,
  `Chj::xtmpfile`:
  operations on filehandles that throw exceptions on errors by
  default, plus many utilities.
  I wrote these around 15 years ago, as a means to offer IO with
  exceptions and more features, but in the mean time alternatives have
  been grown that are probably just as good or better. Do you know
  which replacements this project should be using?

* a few more modules that are used by the above (some originally part
  of [chj-perllib](https://github.com/pflanze/chj-perllib))

* [Htmlgen](htmlgen/README.md), the tool used to generate this
  website, built using the above.


## Documentation

It probably makes sense to look through the docs roughly in the given
order, but if you can't follow the presentation, skip to the intro,
likewise if you're bored skip ahead to the examples and the
howto/design documents.

* [__Introduction to using the functional-perl modules__](//intro.md)

    [This](//intro.md) is the latest documentation addition (thus has
    the best chance of being up to date), and is aiming to give a
    pretty comprehensive overview that doesn't require you to read the
    other docs first. Some of the info here is duplicated (in more
    detail) in the other documents. If this is too long, take a look
    at the presentation below or the example scripts.

* __Presentation__

    [These](http://functional-perl.org/london.pm-talk/) are the slides of
    an introductory presentation, but there's no recording and the slides
    may not be saying enough for understanding. (Todo: add text of
    speach somehow?)

* __Intro directory__

    The [intro](intro/) directory contains scripts introducing the
    concepts, including the basics of functional programming (work in
    progress). The scripts are meant to be viewed in this order:

    1. [basics](intro/basics)
    1. [tailcalls](intro/tailcalls)
    1. [more_tailcalls](intro/more_tailcalls)

    This doesn't go very far yet (todo: add more).

* __Examples__

    The [examples](examples/README.md) directory contains scripts showing
    off the possibilities. You will probably not understand everything
    just from looking at these, but they will give an impression.

* __Our howto and design documents__

    * *[How to write functional programs on Perl 5](docs/howto.md)* is
      describing the necessary techniques to use the functional style on
      Perl. (Todo: this may be too difficult for someone who doesn't know
      anything about functional programming; what to do about it?)

    * *[The design principles used in the functional-perl
      library](docs/design.md)* is descibing the organization and ideas
      behind the code that the functional-perl project offers.

* __Book__

    If you need a more gentle introduction into the ideas behind
    functional programming, you may find it in *[Higher-Order
    Perl](http://hop.perl.plover.com/)* by Mark Jason Dominus.  This book
    was written long before the functional-perl project was started, and
    does various details differently, and IIRC doesn't care about memory
    retention problems (to be fair, at the time the book was written the
    perl interpreter wouldn't have allowed to avoid them anyway). Also,
    IIRC it bundles lazy evaluation into the list elements (pairs);
    separating these concerns should be preferable as they are then
    more universally usable and combinable. (Todo: reread book,
    contact author.)

Please ask [me](http://leafpair.com/contact) or on the
[[mailing_list]] if you'd like to meet up in London or Switzerland to
get an introduction in person.


## Dependencies

* to use `bin/repl` or the repl in the intro and examples scripts
  interactively, `Term::ReadLine::Gnu` and `PadWalker` (and optionally
  `Eval::WithLexicals` if you want to use the :m/:M modes.)

* to run the test suite: `Test::Requires`

* to run all the tests (otherwise some are skipped): in addition to
  the above, `BSD::Resource`, `Method::Signatures`,
  `Function::Parameters`, `Sub::Call::Tail`, `Text::CSV`, `URI`,
  `Text::Markdown`, `Clone`. Some of these are also necessary to run
  `htmlgen/gen` (or `website/gen` to build the website), see
  [Htmlgen](htmlgen/README.md) for details.

(Todo: should all of the above be listed in PREREQ_PM in Makefile.PL?)


## Installation

    git clone https://github.com/pflanze/functional-perl.git
    cd functional-perl

    # to get the latest release, which is $FP_COMMITS_DIFFERENCE behind master:
    git checkout -b $FP_VERSION_UNDERSCORES $FP_VERSION

    # to verify the same against MitM attacks:
    gpg --recv-key 04EDB072
    git tag -v $FP_VERSION
    # You'll find various pages in search engines with my fingerprint

The bundled scripts modify the library load path to find the files
locally, thus no installation is necessary. All modules are in the
`lib/` directory, `export PERL5LIB=path/to/functional-perl/lib` is all
that's needed.

The normal `perl Makefile.PL; make test && make install` process
should work as well. The repository is probably going to be split into
or will produce several separate CPAN packages in the future, thus
don't rely on the installation process working the way it is right
now.


</with_toc>
