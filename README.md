A library for Genetic Programming using grammatical evolution written in [livescript](http://livescript.net/)

For an example of how to use it, see src/examples/single-threaded.ls for a simple script that uses an arithmetic grammar to approximate a polynomial.

For execution, this library depends on the following npm modules:

- underscore
- node-uuid

and for development, it depends on:

- livescript (global installation)
- should.js
- mocha

I haven't gotten round to publishing this as an npm module yet, so you'll have to install the deps manually until I do (and since the compiled js isn't checked in, you'll need livescript to compile it before you can run it). At some point soon I'll fix all this... I promise :)
