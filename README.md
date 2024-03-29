Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

# Functional programming in Perl

This project aims to make it easier to reduce the number of places in
Perl programs where side effects are used, by providing facilities
like data structures to enable it and tutorials and introductions to
show good ways to go about it.

Side effects (mutation and input/output), unless they are contained
locally (transparent to the user of a subroutine/method/API) are not
part of the method/subroutine calling interface but are implicit
(hopefully at least documented), and such a call has lingering
effects, possibly at a distance. This makes tracking down bugs more
difficult, and can hinder the reuse of program parts in newly combined
ways. Also, code that uses side effects may not be idempotent (hence
produce failures) or be calculating different values when re-run,
which prevents its use in an interactive way, like from a read-eval
print loop or debugger, and makes writing tests more difficult.

Functional programming is often associated with strong static typing
(as in Haskell or Scala). Those two complement each other because the
side-effect free model simplifies the description of what a piece of
code does via its types, and types can guarantee that a particular
piece of code is pure. But the same advantages that functional
programs have for machines to reason about are also valid for
humans. Thus you can still benefit from functional programming in a
dynamically typed language like Perl--and you get some additional
interactivity benefits on top.

<with_toc>

## Examples

Work more easily with sequences:

    use Test::More;
    use FunctionalPerl ":all"; # includes autoboxing (methods on arrays work)
    
    is [2, 3, 4]->reduce(\&add), 9; # the `sum` method does the same
    is [2, 3, 4]->map(\&square)->sum, 29;

There are short constructor functions like `list` for non-native data
structures; `equal` knows how to deal with all comparable data
structures:

    use FP::Equal;
    ok equal( ["a".."z"]->chunks_of(2)->take(3)->list,
              list(purearray('a', 'b'), purearray('c', 'd'), purearray('e', 'f')) );

`purearray`s (`FP::PureArray`) are arrays but immutable to prevent
accidental mutation. You could request mutable ones:

    ok equal( ["a".."z"]->chunks_of(2)->take(3)->map(the_method "array")->array,
              [['a', 'b'], ['c', 'd'], ['e', 'f']] );

Make some XML document:

    # Generate functions which construct PXML objects (objects that
    # can be serialized to XML) with the names given her as the XML
    # tag names:
    use PXML::Tags qw(myexample protocol-version records record a b c d);
    # The functions are generated in all-uppercase so as to minimize
    # the chances for naming conflicts and to let them stand apart.

    is RECORD(A("hi"), B("<there>"))->string,
       '<record><a>hi</a><b>&lt;there&gt;</b></record>';

Now create a bigger document, with its inner parts built from external
inputs:

    MYEXAMPLE(
        PROTOCOL_VERSION("0.123"),
        RECORDS(
            csv_file_to_rows($inpath, {eol => "\n", sep_char => ";"})
            # skip the header row
            ->rest
            # map rows to XML elements
            ->map(sub {
                      my ($a,$b,$c,$d) = @{$_[0]};
                      RECORD(A($a), B($b), C($c), D($d))
                  })))
        # print XML document to disk
        ->xmlfile($outpath);

The `MYEXAMPLE` document above is built lazily: `csv_file_to_rows`
returns a *lazy* list of rows, `->rest` causes the first CSV row to be
read and dropped and returns the remainder of the lazy list, `->map`
returns a new lazy list which is passed as argument to `RECORDS`,
which returns a `PXML` object representing a 'records' XML element,
that is then passed to `MYEXAMPLE` which returns a `PXML` object
representing a 'myexample' XML element. `PXML` objects come with an
`xmlfile` method which serializes the document to a file, and only
while it runs, when it encounters the embedded lazy lists, does it walk
those evaluating the list items one at a time and dropping each item
immediately after printing. This means that only one row of the CSV
file needs to be held in memory at any given point.

<small>(Note that the example still assumes that steps have been taken
so that the CSV file doesn't change until the serialization step has
completed, otherwise functional purity is broken; the responsibility
to ensure this assumption is left to the programmer (see
[[howto#Pure_functions_versus_I/O_and_other_side-effects]] for more
details about this).)</small>

The core idea of functional programming is the avoidance of
mutation. In the absense of mutation, a value, once calculated, stays
the same, it is immutable. For example numbers: once a number is
calculated you can't modify it in place; if you have multiple
variables holding the same number, you can't (on purpose or
accidentally) change them both at the same time:

    my $x = 100;
    my $y = $x;
    $x++;
    is $y, 100; # still true, the number itself didn't change, only the variable

There is no number operation that modifies numbers in place, they all
return a new number instance. The same isn't true for most other
values in Perl; they let you modify their internal contents without
giving you a new reference, and it's usually the default way how
things are done. Strings and sometimes arrays are often copied
instead, which for large instances becomes inefficient. Setters on
objects usually just modify an object in place (they mutate it). This
project helps both with efficiency (minimizing copying) and ergonomy
(automatically creates functional setters for class fields).
[Here's an example](examples/functional-classes) with a simple class
to show the difference.

Code that doesn't mutate (pure functions or methods) can be combined
easily into new functions, which are still pure and thus can be
further combined. `compose` takes any number of function references
(coderefs) and returns a new function (coderef) that applies those
functions to its argument in turn (it is a combinator function, there
are more in`FP::Combinators`):

    # The function that adds all of its arguments together then
    # squares the result:
    *square_of_the_sum = compose \&square, \&add;
    is square_of_the_sum(10,20,2), 1024;

    # The same but takes the input items from a list instead of
    # multiple function arguments:
    *square_of_the_sequence_sum = compose(\&square, the_method "sum");
    is square_of_the_sequence_sum(list(2, 3)), 25;

Functional programming matters more in the large--with small programs
it's easy to keep all places where mutation happens in the head,
wheras with large ones the interactions can become unwieldy.

See the [examples](examples/README.md) page for more examples.

If you'd like to see a practical step-by-step introduction, read the
[[intro]]. Or check the [The Perl Weekly Challenges,
\#113](docs/blog/perl-weekly-challenges-113.md) blog post, it
introduces many features given concrete tasks, for which various
standard Perl solutions have also been written.

For an index into all modules, see the "see also" section in
`FunctionalPerl`.


## Status: alpha

This project is in alpha status because:

* Handling of streams (lazy lists) is currently unergonomic since the
  user has to specify explicitly whether a stream is to be retained
  (using of `Keep` function) or to be let go (default). Ideally the
  perl interpreter is extended with a pragma that, when enabled, makes
  it automatically keep or let go of a value, depending on whether a
  variable is still used further down (lexical analysis).

* The project is currently using some modules which the author
  developed a long time ago and could be replaced with other existing
  ones from CPAN (e.g. `Chj::xperlfunc`, `Chj::IO::`).

* `FP::Struct` was implemented as a class generator for classes that
  come with functional setters (setters which don't mutate the
  objects, but return modified versions). The author also liked to see
  where a very simple approach may lead to (e.g. use of predicate
  functions for type checking). The aim was to provide a very easy and
  concise way to write classes. This is experimental, and may be
  deprecated in favour of extending existing class generators where
  needed and using them instead.

* The namespaces are not fixed yet (in particular, everything in
  `Chj::` should probably be renamed); also, the interfaces should be
  treated as alpha. More abstract types (similar to
  `FP::Abstract::Sequence`) should be defined.

* Get it working correctly first, then fast: some operations aren't
  efficient yet. There is no functional sequence data structure yet
  that allows efficient random access, and none for functional
  hashmaps with efficient updates, but the author has plans to address
  those. Also the author has plans for implementing mechanisms to make
  chains of sequence operations (like
  `$foo->map($bar)->filter($baz)->drop(10)->reverse->drop(5)`) as
  performant as the imperative equivalent.

There is a lot that still needs to be done, and it depends on the
author or other people be able and willing to invest the time.

(An approach to use this project while avoiding breakage due to future
changes could be to add the
[functional-perl Github repository](https://github.com/pflanze/functional-perl)
as a Git submodule to the project using it and have it access it via
`use lib`. Tell if you'd like to see stable branches of older versions
with fixes.)


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

* some developer utilities: `FP::Repl`, `Chj::ruse`, `Chj::Backtrace`,
  `FP::Repl::Trap`.

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

    This is the latest documentation addition (thus has the best
    chance of being up to date), and is aiming to give a pretty
    comprehensive overview which doesn't require you to read the other
    docs first. Some of the info here is duplicated (in more detail)
    in the other documents. If this is too long, take a look at the
    presentation below or the example scripts.

* [__Presentation__](http://functional-perl.org/london.pm-talk/)

    These are the slides of an introductory presentation, but there's
    no recording and the slides may not be saying enough for
    understanding. It's also somewhat outdated.

* [__Intro directory__](intro/)

    The `intro` directory contains scripts introducing the concepts,
    including the basics of functional programming (work in
    progress). The scripts are meant to be viewed in this order:

    1. [basics](intro/basics)
    1. [tailcalls](intro/tailcalls)
    1. [more_tailcalls](intro/more_tailcalls)

    This doesn't go very far yet (todo: add more). Also, please note
    that `Sub::Call::Tail` is currently broken with newer Perl
    versions (todo: look into fixing it or whether it is possible to
    imlement it in a simpler manner).

* [__Examples__](examples/README.md)

    The `examples` directory contains scripts showing off the
    possibilities. You will probably not understand everything just
    from looking at these, but they will give an impression.

* __Our howto and design documents__

    * *[How to write functional programs in Perl 5](docs/howto.md)* is
      describing the necessary techniques to use the functional style in
      Perl. (Todo: this may be too difficult for someone who doesn't know
      anything about functional programming; what to do about it?)

    * *[The design principles used in the functional-perl
      library](docs/design.md)* is describing the organization and ideas
      behind the code that the functional-perl project offers.

* __Book__

    If you need a more gentle introduction into the ideas behind
    functional programming, you may find it in *[Higher-Order
    Perl](http://hop.perl.plover.com/)* by Mark Jason Dominus.  This book
    was written long before the functional-perl project was started, and
    does various details differently.

Please ask [me](http://leafpair.com/contact) if you'd like to meet up
in London, Berlin or Switzerland to get an introduction in person.


## Dependencies

* to use `bin/perlrepl`, `bin/fperl` or the repl in the intro and
  examples scripts interactively, `Term::ReadLine::Gnu` and
  `PadWalker` (and optionally `Eval::WithLexicals` if you want to use
  the :m/:M modes, and `Capture::Tiny` to see code definition location
  information and `Sub::Util` from `Scalar::List::Utils` to see
  function names when displaying code refs.)

* to run the test suite: `Test::Requires`

* to run all the tests (otherwise some are skipped): in addition to
  the above, Perl version >= 5.020, `Test::Pod::Snippets`,
  `BSD::Resource`, `Method::Signatures`, `Sub::Call::Tail`,
  `Text::CSV`, `DBD::CSV`, `Text::CSV`, `URI`, `Text::Markdown`,
  `Clone`. Some of these are also necessary to run `htmlgen/gen` (or
  `website/gen` to build the website), see
  [Htmlgen](htmlgen/README.md) for details.

* some examples also use: `JSON`

(Todo: should all of the above be listed in PREREQ_PM in Makefile.PL?)

You can run `meta/install-development-dependencies-on-debian` to get
those installed if you're on a Debian system.


## Installation

### From CPAN

Use your preferred CPAN installer, for example: `cpan
FunctionalPerl`. Note that this one installs the "runtime recommends"
dependencies as well, which is a lot (like e.g. DBI), so you may want
to look through the `Makefile.PL` or the list below and install what
you can from your Linux distribution or other binary package
repository first. Or if you don't want the recommends, set
`recommends_policy` in `$ENV{HOME}/.cpan/CPAN/MyConfig.pm` to 0, or
install the cpanminus tool and run `cpanm FunctionalPerl` which skips
recommends unless you pass the `--with-recommends` option.

### From the Git repository

    git clone https://github.com/pflanze/functional-perl.git
    cd functional-perl

    # To get the latest release, which is $FP_COMMITS_DIFFERENCE behind master:
    git checkout -b $FP_VERSION_UNDERSCORES $FP_VERSION

    # To verify the same against MitM attacks:
    gpg --recv-key 04EDB072
    git tag -v $FP_VERSION
    # You'll find various pages in search engines with my fingerprint,
    # or you may find a trust path through one of the signatures on my
    # older key 1FE692DA, that this one is signed with.

The bundled scripts modify the library load path to find the files
locally, thus no installation is necessary. All modules are in the
`lib/` directory, `export PERL5LIB=path/to/functional-perl/lib` is all
that's needed.

To install, run the usual `perl Makefile.PL; make test && make install`.

(The repository might be split into producing several separate CPAN
packages (or even repositories?) in the future, thus don't rely too
much on the installation process continuing to work the way it is
right now.)


## Reporting bugs, finding help, contributing

* Report bugs via either:

    * the [Github project](https://github.com/pflanze/functional-perl)

    * the "Issues" link on the the distribution's
      [metacpan page](https://metacpan.org/pod/FunctionalPerl).

* Find IRC and contact details on the [[mailing_list]] and [[contact]]
  pages. Check the [[design]] page to get an idea about the design
  principles if you'd like to write code to contribute.


</with_toc>
