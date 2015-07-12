Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

# Functional XML (and HTML, SVG, ..) generation

PXML intends to be a simple, Perl based representation for XML, or at
least the subset that's necessary for doing most tasks. Currently it
doesn't support XML namespaces properly (manually prefixing element
names may be a workable solution, though?). It is primarily meant to
*produce* XML output; parsing of XML is of secondary interest (but
[Htmlgen](../htmlgen/README.md) already has [some
code](../htmlgen/Htmlgen/Htmlparse.pm) to parse by way of
`HTML::TreeBuilder`).

Its in-memory representation are `PXML::Element` (or subclassed)
objects. Serialization is done using functions/procedures from
`PXML::Serialize`.

The body of elements can be a mix of standard Perl arrays,
`FP::PureArray`s, linked lists based on `FP::List`, and promises
(`FP::Lazy`, `FP::Stream`), the latter of which allow for the
generation of streaming output (which means the document is generated
while it is being serialized, thus there's no memory needed to hold
the whole document at once).

Direct creation of XML elements:

    use PXML::Element;
    my $element= PXML::Element->new
          ("a", {href=> "http://myserver.com"}, ["my server"]);

Using 'tag functions' for shorter code:

    use PXML::XHTML;
    my $element= A({href=> "http://myserver.com"}, "my server");
    my 

See [`test`](test) and [`testlazy`](testlazy) for complete examples,
and [`examples/csv_to_xml`](../examples/csv_to_xml) for a simple real
example, and [`htmlgen/gen`](../htmlgen/gen) for the program that
generates this website. `FP::DBI` is supposed to fit well with PXML.

## Module list

`PXML`,
`PXML::XHTML`,
`PXML::HTML5`,
`PXML::SVG`,
`PXML::Tags`,
`PXML::Serialize`,
`PXML::Util`

## Comparison with CGI.pm

When generating HTML, `CGI`'s tag functions seem similar, what are
the differences?

 - PXML::XHTML chooses upper-case constructor names to reduce the
   chances for conflicts; for example using "tr" for <TR></TR>
   conflicts with the tr builtin Perl operator.

 - `CGI`'s creators return strings, whereas PXML::XHTML returns
   PXML::Element objects. The former might have O(n^2) complexity with the
   size of documents (getting slower to concatenate big strings),
   while the latter should have constant overhead. Also, PXML can be
   inspected after creation, an option not possible with `CGI`
   (without using an XML parser).

 - PXML serialization always escapes strings, hence
   is safe against XSS, while `CGI` does/is not.

 - PXML has chosen not to support dashes on attributes,
   like `{-href=> "foo"}`, as the author feels that this is unnecessary
   clutter both for the eyes and for the programmer wanting to access
   attributes from such hashes, and added complexity/runtime cost for
   the serializer.

 - `CGI`'s tag functions are actually deprecated now.


## Naming

Perhaps PXML should be renamed to FXML. The idea behind PXML was
originally to provide something similar to
[SXML](https://en.wikipedia.org/wiki/SXML), using Perl arrays and
hashes (hence 'P' instead of 'S'), but that has proven to be pretty
impractical, wrapper functions producing blessed objects is a much
better user interface.

