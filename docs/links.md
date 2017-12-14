Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

# Various links

## Function libraries

* [srfi-1](http://srfi.schemers.org/srfi-1/srfi-1.html), the list
  library for Scheme

* [Hoogle](https://www.haskell.org/hoogle/), finding functions in
  standard Haskell libraries

* [core-api](http://clojure.github.io/clojure/clojure.core-api.html),
  Clojure core function docs

## Functional programming in X

* [Professor Frisby's Mostly Adequate Guide to Functional Programming (in javascript)](https://github.com/DrBoolean/mostly-adequate-guide)
  ([HN](https://news.ycombinator.com/item?id=9884616)).
  Also see:

    * [ES6 Tail Call Optimization Explained](http://benignbemine.github.io/2015/07/19/es6-tail-calls/)
    * [Trampolines in JavaScript](http://raganwald.com/2013/03/28/trampolines-in-javascript.html)
        * (also [Paste from holmberd](http://paste.ubuntu.com/ 24568118/))
    * [lemonad](http://fogus.github.io/lemonad/)
    * [Rambda](http://ramdajs.com/)
        * [Introducing Ramda](http://buzzdecafe.github.io/code/2014/05/16/introducing-ramda) <small>*" Ramda includes all of the favorite list-manipulation functions you expect, e.g. map, filter, reduce, find, etc. But Ramda is significantly different from libraries like Underscore and Lodash. ..."*</small>
    * [All About Recursion, PTC, TCO and STC in JavaScript](http://lucasfcosta.com/2017/05/08/All-About-Recursion-PTC-TCO-and-STC-in-JavaScript.html)

* [Functional Programming in Python
  (pdf)](http://www.oreilly.com/programming/free/files/functional-programming-python.pdf)
  ([HN](https://news.ycombinator.com/item?id=9941748))

* [PyFunctional](http://pedrorodriguez.io/PyFunctional/)

    * [main Github repo?](https://github.com/EntilZha/PyFunctional) ([HN](https://news.ycombinator.com/item?id=15919646))
        * also: pipetools, itertools

* [Functional programming in C++](http://gamasutra.com/view/news/169296/Indepth_Functional_programming_in_C.php) ([John Carmack](https://en.wikipedia.org/wiki/John_Carmack)) ([alternative link](https://web.archive.org/web/20130819160454/http://www.altdevblogaday.com/2012/04/26/functional-programming-in-c/))

* [Lua Functional](https://github.com/rtsisyk/luafun)
  ([docs](http://rtsisyk.github.io/luafun/index.html),
   [HN](https://news.ycombinator.com/item?id=6770698))
  (also, [functional-lua](https://github.com/jhoonb/functional-lua))

* [The FSet Functional Collections Libraries (Common Lisp)](https://common-lisp.net/project/fset/Site/index.html) ([Github](https://github.com/slburson/fset))

* [C# Functional Language Extensions](https://github.com/louthy/language-ext)


## Functional programming courses

* [Introduction to Functional
  Programming](https://www.edx.org/course/introduction-functional-programming-delftx-fp101x-0):
  the interesting part here may be that this course is said to show
  "[that good OOP code is actually
  functional](https://www.quora.com/How-does-Scala-compare-to-F-as-a-functional-language)". (I
  haven't verified, but would expect it to show why you want your
  objects to be immutable, which applies to the `FP::Struct` model.)

* [Purely Functional Data Structures for the Impure (by osmaferon)](http://osfameron.github.io/pure-fp-book/) ([source](https://github.com/osfameron/pure-fp-book))

## Functional programming in various contexts

* [Pure UI](http://rauchg.com/2015/pure-ui/), on purely functional
  composition of a user interface (using the
  [React](https://en.wikipedia.org/wiki/React_(JavaScript_library))
  JavaScript library)

* [Write code that is easy to delete, not easy to extend](http://programmingisterrible.com/post/139222674273/write-code-that-is-easy-to-delete-not-easy-to):
  even though the article doesn't mention functional programming, it
  helps this aim (pure functions don't depend on state, hence
  dependencies are on code only)

* [in which we plot an escape from the quagmire of equality](http://technomancy.us/159), nice citation: *(...) referential transparency allows you to have much greater confidence that your code is correct. Without it, the best you can say is "as long as the rest of this program behaves itself, this function should work". This works a lot like older OSes with cooperative multitasking and no process memory isolation*; also discusses equality, and proposes adding immutable data types to Emacs.


## Testing

* [How I Write Tests](https://blog.nelhage.com/2016/12/how-i-test/)
  (Functional Perl helps satisfy most of these points; "Write lots of
  fakes" may really be asking for a monad abstraction.)
  ([HN](https://news.ycombinator.com/item?id=13296589)), also [Design
  for
  Testability](https://blog.nelhage.com/2016/03/design-for-testability/)

## Experiments

* [The list monad in Perl and
  Python](http://blog.plover.com/prog/monad-search-2.html)
  (by mjd, author of *[Higher-Order Perl](http://hop.perl.plover.com/)*)
  ([HN](https://news.ycombinator.com/item?id=10002173))

