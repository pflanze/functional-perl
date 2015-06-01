# Functional programming on Perl 5

This project aims to provide modules as well as tutorials and
introductionary materials and other knowledge to work in a functional
style on Perl.

## Status: experimental

The project should not be used for production code yet for the
following reasons:

* the chosen namespaces and interfaces are still in flux; it hasn't
  been released to CPAN yet for this reason

* some modules may be replaced with other more widely used ones in the
  interest of keeping with the common base

* tutorials are not complete yet, and less experienced Perl
  programmers will have difficulties writing or debugging code in this
  style on Perl without proper introduction

* some problems in the perl interpreter leading to memory leaks or
  retention issues when using this style have only been fixed
  recently, and some more exotic ones are still waiting to be fixed

We are welcoming anyone interested to play with the code, ask
questions, provide feedback, and perhaps contribute examples, ideas or
teaching materials.  We are also hoping to work with interested core
perl developers on fixing the remaining issues in the interpreter.

Please send [me](http://leafpair.com/contact) your suggestions!


## Parts

* [FP::Struct](lib/FP/Struct.pm): a class generator that creates
  functional setters and takes predicate functions for type checking

* [lib/FP/](lib/FP/): library of pure functions and
  functional data structures

* [PXML](lib/PXML.pm),
  [PXML::XHTML](lib/PXML/XHTML.pm),
  [PXML::HTML5](lib/PXML/HTML5.pm),
  [PXML::SVG](lib/PXML/SVG.pm),
  [PXML::Tags](lib/PXML/Tags.pm),
  [PXML::Serialize](lib/PXML/Serialize.pm):
  "templating system" for XML based markup languages by way of Perl
  functions. Docs and tests are in [ftemplate/](ftemplate/).

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
  Should probably be dropped in favor of something else, suggestions
  welcome.

* a few more modules that are used by the above (some originally part
  of [chj-perllib](https://github.com/pflanze/chj-perllib))


## Functional programming in Perl 5

We feel that the Scheme language approaches functional programming
very nicely. Like Perl, Scheme is not a purely functional language,
and like Perl it is not lazy by default. Both languages have lexical
scoping by default (and dynamic scoping on request, Scheme's
`make-parameter` and `parameterize` corresponding to Perl's `our` and
`local`), and both are providing closures. Thanks to this, translating
the principles used in Scheme to Perl is quite straight-forward,
except that Perl's syntax poses some overheads, and Perl's interpreter
requires some hand-holding to free memory correctly in some
situations.

These are the real differences between Perl and Scheme that concern
functional programs:

- Sigils: Perl has separate namespaces (syntactically distinguished)
for functions, scalars, arrays, hashes. Scheme only has one
namespace. Using only one namespace has the benefit of uniformity;
passing values the same way regardless of their kind is necessary for
generic functions, and references need to be taken in Perl in these
cases. Thus, functional programs will either use reference-taking
syntax like `\@foo`, `\&bar` etc. often, or store references in
scalars from the start (like `my $foo= []`).

- Tail-calls: Scheme guarantees tail-call optimization. This means
that Scheme functions can call other functions in tail position
endlessly whereas Perl will run out of memory due to increasing stack
space used.  But Perl has the `goto \&func` construct which calls func
without allocating a new stack frame; parameters need to be passed by
assigning them to `@_`. With that, tail call optimization is possible,
but instead of the system doing it automatically, it has to be
specified explicitely. Admittedly the syntax for this is ugly; but
thankfully there's already a module that improves on this:
`Sub::Call::Tail`; see
[intro/more_tailcalls](intro/more_tailcalls) for
examples.

- Leak potential: Scheme implementations are usually written with
functional programs in mind and hence take care that they work
transparently in all (usual) cases; Perl not so much. Perl assumes a
style of programming where local scopes are exited quickly and hence
doesn't care to free memory that can't be accessed further down in the
scope anymore. (Retaining it can also be useful for debugging, and
since Perl programs can inspect the stack, they actually *can*
arbitrarily access those values, even if normal programs don't do
that.) This poses a problem with the idiom of lazily generated deeply
nested data structures (like lazily computed linked lists aka
"functional streams"). In those cases, the Perl program has to
explicitely set unused references that remain in the scope to undef or
use WeakRef on the same. In the case of arguments passed to functions,
the called function has to get rid of that reference if necessary by
deleting it from the outer call frame through `@_` (like `undef
$_[1];`) Note that on older versions of Perl deleting references
through `@_` doesn't always work (v5.14.2 is fine, v5.10.1 is not).

    Note: weaken'ed references to closures that return closures
    (e.g. through `lazy`) won't be retained; `my $f=$f;` needs to be
    used before the `lazy` form.

- C stack when freeing: When Perl deallocates nested data structures,
it uses space on the C (not Perl language) stack for the
recursion. When a structure to be freed is nested deeply enough (like
with long linked lists), this will make the interpreter run out of
stack space, which will be reported as a segfault on most
systems. There are two different remedies for this:

    - increase system stack size by changing the corresponding
    resource limit (e.g. see `help ulimit` in Bash.)

    - don't let go of a deeply nested structure at once. Again, this
    is done by letting go of the outer layers (like the head of the
    list) in a timely manner, thus the same solutions as discussed on
    "Leak potential" apply.


## Intro

The [intro](intro/) directory contains scripts introducing the
concepts, including the basics of functional programming (work in
progress). The scripts are meant to be viewed in this order:

    basics
    tailcalls
    more_tailcalls

The [examples](examples/) directory contains scripts showing off the
possibilities.

### Presentation

You can find slides of a presentation on the project
[here](http://functional-perl.org/london.pm-talk/).


## Installation

For simplicity during development there is no installer support,
instead the bundled scripts modify the library load path to find the
files locally.

## Dependencies

* to run the test suite: `Test::Requires`

* to run all the tests (otherwise some are skipped):
  `BSD::Resource`, `Method::Signatures`, `Text::CSV`, `URI`

* to use `bin/repl` interactively, `Term::ReadLine::Gnu`

* to use nicer syntax for tail call optimization: `Sub::Call::Tail`


## See also

* For a real program using these modules, see
  [ml2json](http://ml2json.christianjaeger.ch).

* A [post](https://news.ycombinator.com/item?id=8734719) about streams
  in Scheme mentioning the memory retention issues that even some
  Scheme implementations can have.

* [functional-shell](https://github.com/pflanze/functional-shell) is a
  work in progress to allow writing functional programs in Bash,
  although rather for illustration than for practical use.
