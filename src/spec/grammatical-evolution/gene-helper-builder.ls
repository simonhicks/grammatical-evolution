should = require \should
_ = require \underscore

{GeneHelperBuilder} = require '../../grammatical-evolution/gene-helper-builder'

suite 'GeneHelperBuilder', ->

  suite 'when being configured', ->
    test-argument = (field-name, dflt) ->
      test "#field-name should default to #dflt", ->
        builder = new GeneHelperBuilder()
        builder.get(field-name).should.equal(dflt)

      test "#field-name should be configurable", ->
        opts = {}
        opts[field-name] = Math.random()
        builder = new GeneHelperBuilder opts
        builder.get(field-name).should.equal(opts[field-name])

    test-argument \base, 2
    test-argument \codonBits, 8

  suite 'when using a binary helper object', ->
    # these are equivalent
    ints = [0, 1, 2, 3, 4, 5, 6, 7]
    bits = '00000001001000110100010101100111'

    setup ->
      @opts =
        base: 2
        codon-bits: 4
      @create-helper = -> new GeneHelperBuilder(@opts).build()

    test 'should build a helper object', ->
      @create-helper().should.be.an.instance-of Object

    test 'the helper should convert bits to ints', ->
      helper = @create-helper()
      helper.bits-to-ints(bits).should.eql ints

    test 'the helper should convert ints to bits', ->
      helper = @create-helper()
      helper.ints-to-bits(ints).should.eql bits

    test "changing the @opts in the builder, shouldn't affect the helper once it's created"
