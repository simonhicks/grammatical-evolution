_ = require \underscore

class exports.GeneHelperBuilder
  defaults =
    base: 2
    codon-bits: 8
    point-mutation-rate: 1
    crossover-rate: 0.3
    duplication-rate: 1
    deletion-rate: 0.5
    number-of-codons: 10

  (config={}) ->
    _.extend @opts={}, defaults, config

  get: (field) -> @opts[field]

  build: ->
    # create local versions of the configuration variables
    {codon-bits,base,point-mutation-rate,crossover-rate,duplication-rate,deletion-rate,number-of-codons} = @opts

    # this is the actual helper object
    helper-object = new
      @bits-to-ints = (bits) ~>
        codons = split-bitstring bits
        _.map codons, (c) -> parse-int c, base

      @ints-to-bits = (ints) ~>
        _(ints).map(~> it.to-string(base) |> pad).join('')

      @mutate-point = (bits) ~>
        child = _.map bits, (bit) ~>
          if maybe(point-mutation-rate/bits.length) then flip-bit bit else bit
        child.join ''

      @single-point-crossover = (p1, p2) ~>
        if (maybe crossover-rate)
          p1-ints = @bits-to-ints p1
          p2-ints = @bits-to-ints p2
          cut = random-int(_.min([p1-ints.length, p2-ints.length]))
          @ints-to-bits p1-ints[0 til cut].concat(p2-ints.slice(cut))
        else
          p1

      @duplicate-codon = (bits) ~>
        if (maybe duplication-rate/codon-bits)
          ints = @bits-to-ints bits
          i = random-int(ints.length)
          ints.push ints[i]
          @ints-to-bits ints
        else
          bits

      @delete-codon = (bits) ~>
        if (maybe deletion-rate/codon-bits)
          ints = @bits-to-ints bits
          i = random-int ints.length
          res = ints[0 til i].concat ints.slice(i + 1)
          @ints-to-bits res
        else
          bits

      @random-bitstring = ~>
        [random-int base for i from 0 til number-of-codons] |> @ints-to-bits

      @reproduce = (p1, p2) ~>
        @single-point-crossover p1, p2 |> @duplicate-codon |> @delete-codon |> @point-mutation

      this

    # internal helpers for this object (ie. "private" functions)

    # split a bitstring into codons of length `bitstring`
    function split-bitstring(bitstring)
      re = new RegExp(".{#codon-bits}", 'g')
      bitstring.match re

    # pad a bitstring with zeros, so it has length `bitstring`
    function pad(s)
      ('0' * (codon-bits - s.length)) + s

    # mutate an individual bit
    function flip-bit(bit)
      if base is 2
        1 .^. parse-int(bit, base)
      else
        options = [b for b from 0 til base when "#b" isnt "#bit"]
        options[random-int options.length]

    # return `true` with a probability of `p` else, `false`
    function maybe(p)
      Math.random() < p


    # return a random integer between 0 (incl) and `limit` (excl)
    function random-int(limit)
      Math.floor(Math.random() * limit)

    helper-object
