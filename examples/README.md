(Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.)

---

# Examples

Some examples showing the possibilities using [functional-perl](../README.md).

* [`fibs`](fibs) and [`primes`](primes) show translations of Haskell programs.

* [`gen-csv`](gen-csv) and [`csv_to_xml`](csv_to_xml) show how to stream
  number series into and from CSV files and into XML.

* [`diff_to_html`](diff_to_html) hows how to generate (X)HTML.

* [`skip`](skip) shows how to implement a sliding window (look-ahead) as a
  pure function (that can easily be tested) and then uses it for IO

These are really just test suites, but perhaps still instructive:

* [`dbi`](dbi) shows/tests usage of `FP::DBI`

* [`predicates`](predicates) shows/tests `FP::Predicates`

Copy [`template`](template) to create your own script.


## See also

* For a real program using these modules, see
  [ml2json](http://ml2json.christianjaeger.ch), although it still
  bundles a much older version of the functional-perl libraries (todo:
  update to use the current functional-perl instead)

