_ = require \underscore

class exports.GeneHelperBuilder
  defaults =
    base: 2
    codon-bits: 8

  (config={}) ->
    _.extend @opts={}, defaults, config

  get: (field) -> @opts[field]

  build: ->
    # create local versions of the configuration variables
    {codon-bits, base} = @opts

    # this is the actual helper object
    helper-object =
      bits-to-ints: (bs) ->
        codons = split-bitstring bs
        _.map codons, (c) -> parse-int c, base

      ints-to-bits: (ints) ->
        _(ints).map(~> it.to-string(base) |> pad).join('')

    # internal helpers for this object (ie. "private" functions)
    function split-bitstring(bitstring)
      re = new RegExp(".{#codon-bits}", 'g')
      bitstring.match re

    function pad(s)
      ('0' * (codon-bits - s.length)) + s

    helper-object

