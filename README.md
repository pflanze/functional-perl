# functional-perl - A collection of libraries for functional programming in Perl 5

We feel that the Scheme language approaches functional programming
very nicely. Like Perl, Scheme is not a purely functional language,
and like Perl it is not lazy by default. Translating the principles
used in Scheme to Perl is quite straight forward, and they work in
Perl 5 programs just as well, except that Perl's syntax poses overhead
for working with first-class functions, and Perl's interpreter
requires some hand-holding to avoid leaking memory in some situations.

## More detail, please...

There are 3 relevant differences between Perl and Scheme with regards
to functional programs:

- Perl has separate namespaces (syntactically distinguished) for
functions, scalars, arrays, hashes. Scheme only has one namespace. In
functional programs passing values by reference is an important part
for performance; because of the separate namespaces one has to prefix
references (\@foo, \&bar ..) unless one is willing to do away with the
separate namespacing and puts everything into the namespace of
scalars. There's no such complication in Scheme.

- Scheme implementations are usually written to deal with functional
programs in mind; Perl not so much. Avoiding leaks due to circular
references is a complication, avoiding leaks due to references being
left on the call stack another.

[- XXX what was the third again? ]

XXX finish writing the intro


XXX outlook, open work. Syntax improvement ideas?
