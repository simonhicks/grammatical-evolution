should = require \should
_ = require \underscore

{GeneHelperBuilder} = require '../../grammatical-evolution/gene-helper-builder'

# stubs Math.random so it returns the expected results in sucession, then constant (or the original
# random function if constant doesn't exist)
function with-predictable-random(expected, constant, code)
  try
    old-random = Math.random
    Math.random = -> expected.shift() ? if constant? then constant else old-random()
    code()
  finally
    Math.random = old-random

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
    test-argument \pointMutationRate, 1
    test-argument \crossoverRate, 0.3
    test-argument \duplicationRate, 1
    test-argument \deletionRate, 0.5
    test-argument \numberOfCodons, 10

    test "changing the @opts in the builder, shouldn't affect the helper once it's created", ->
      opts =
        base: 2
        codon-bits: 1
      builder = new GeneHelperBuilder(opts)
      helper = builder.build()
      # changing the builder's base to 10 won't make the helper support decimal strings
      builder.opts.base = 10
      helper.bits-to-ints('234').should.not.eql [2, 3, 4]

  suite 'when using a binary helper object', ->
    # these are equivalent
    ints = [0, 1, 2, 3, 4, 5, 6, 7]
    bits = '00000001001000110100010101100111'

    setup ->
      @opts =
        base: 2
        codon-bits: 4
        point-mutation-rate: 2
        crossover-rate: 0.3
        duplication-rate: 1
        deletion-rate: 0.5
        number-of-codons: 10
      @helper = new GeneHelperBuilder(@opts).build()

    test 'should build a helper object', ->
      @helper.should.be.an.instance-of Object

    suite 'for converting between bits and ints', ->
      test 'the helper should convert bits to ints', ->
        @helper.bits-to-ints(bits).should.eql ints

      test 'the helper should convert ints to bits', ->
        @helper.ints-to-bits(ints).should.eql bits

    suite 'for point mutation', ->
      test 'should perform point mutation', ->
        with-predictable-random [0], 1, ~>
          @helper.mutate-point '01111111' .should.equal '11111111'

      test 'should mutate with a probability of point-mutation-rate/length of bitstring', ->
        bits = '00000000'
        expected-prob = 2 / bits.length
        with-predictable-random [0, expected-prob - 0.01, expected-prob + 0.01], 1, ~>
          @helper.mutate-point(bits).should.equal '11000000'

    suite 'for single point crossover', ->
      test "the helper should perform single point crossover", ->
        # 0 to ensure the crossover occurs, and 0.5 to choose the cut point
        with-predictable-random [0, 0.5], 1, ~>
          p1 = '00000000'
          p2 = '11111111'
          @helper.single-point-crossover(p1, p2).should.equal '00001111'

      test 'should respect codon boundaries', ->
        # 0 to ensure the crossover occurs, and 0.5 to choose the cut point
        with-predictable-random [0, 0.5], 1, ~>
          p1 = '0000000000000000'
          p2 = '1111111111111111'
          # the cut point is rounded down from the middle to the preceding codon boundary
          # (cut should be at 1 + 0.5 * (length - 1) => 2.5 => 2
          @helper.single-point-crossover(p1, p2).should.equal '0000000011111111'

      test 'should crossover at a random point', ->
        with-predictable-random [0, 0.3], 1, ~>
          p1 = '00000000000000000000'
          p2 = '11111111111111111111'
          @opts.codon-bits = 2
          @helper = new GeneHelperBuilder @opts .build()
          @helper.single-point-crossover p1, p2 .should.equal '00000011111111111111'

      test 'should crossover with a probability of crossover-rate', ->
        prob = @opts.crossover-rate
        p1 = '00000000'
        p2 = '11111111'
        crossed-over = '00001111'
        not-crossed = '00000000'
        # set up Math.random() results to alternate between `crossover-decisions` and `cut-points`
        crossover-decisions = [0, prob - 0.001, prob + 0.001, 1]
        cut-points = [0.5, 0.5, 0.5, 0.5]
        results = _.zip crossover-decisions, cut-points
        with-predictable-random _.flatten(results), 1, ~>
          @helper.single-point-crossover p1, p2 .should.equal crossed-over # using result 0
          @helper.single-point-crossover p1, p2 .should.equal crossed-over # using result prob - 0.001
          @helper.single-point-crossover p1, p2 .should.equal not-crossed # using result prob + 0.001
          Math.random().should.equal 0.5 # popping off one of the cut-point randoms
          @helper.single-point-crossover p1, p2 .should.equal not-crossed # using result 1

    suite 'for codon duplication', ->
      test 'the helper should perform codon duplication', ->
        bits = '00000000'
        with-predictable-random [0], null, ~>
          @helper.duplicate-codon bits .should.equal '000000000000'

      test 'should duplicate a random codon', ->
        bits = '00001111'
        # 0 to ensure the duplication occurs, 0.99 to ensure the second codon is selected
        with-predictable-random [0, 0.99], null, ~>
          @helper.duplicate-codon bits .should.equal '000011111111'

      test 'should duplicate with a probability of duplication-rate/codon-bits', ->
        bits = '00001111'
        duplicated = '000011110000'
        not-duplicated = '00001111'
        # prepare "random" results
        prob = @opts.duplication-rate / @opts.codon-bits
        duplication-decisions = [0, prob - 0.01, prob + 0.01, 1]
        cut-points = [0, 0, 0, 0]
        results = _.zip duplication-decisions, cut-points
        with-predictable-random _.flatten(results), 1, ~>
          @helper.duplicate-codon bits .should.equal duplicated # using result 0
          @helper.duplicate-codon bits .should.equal duplicated # using result prob - 0.01
          @helper.duplicate-codon bits .should.equal not-duplicated # using result prob + 0.01
          Math.random().should.equal 0 # popping off one of the cut-point randoms
          @helper.duplicate-codon bits .should.equal not-duplicated # using result 1

    suite 'for codon deletion', ->
      test 'the helper should perform codon deletion', ->
        bits = '0000000000001111'
        with-predictable-random [0], 0.99, ~>
          @helper.delete-codon bits .should.equal '000000000000'

      test 'should delete a codon at a random position', ->
        bits = '000011110000'
        # 0 to ensure duplication occurs, 0.5 to ensure the second codon is selected
        with-predictable-random [0, 0.5], null, ~>
          @helper.delete-codon bits .should.equal '00000000'

      test 'should delete with a probability of deletion-rate/codon-bits', ->
        bits = '000011110000'
        deleted = '00000000'
        not-deleted = '000011110000'
        # prepare "random" results
        prob = @opts.deletion-rate / @opts.codon-bits
        deletion-decisions = [0, prob - 0.01, prob + 0.01, 0.99]
        cut-points = [0.5, 0.5, 0.5]
        results = _.zip deletion-decisions, cut-points
        with-predictable-random _.flatten(results), null, ~>
          @helper.delete-codon bits .should.equal deleted # using result 0
          @helper.delete-codon bits .should.equal deleted # using result prob - 0.01
          @helper.delete-codon bits .should.equal not-deleted # using result prob + 0.01
          Math.random() # popping off one of the cut-point randoms
          @helper.delete-codon bits .should.equal not-deleted # using result 1

    suite 'for generating random bitstrings', ->
      test 'should generate a random bitstring of the pre-configured length', ->
        @helper.random-bitstring().should.have.length @opts.number-of-codons * @opts.codon-bits

  suite 'when using a non-binary helper object', ->
    test 'mutate-point works as expected', ->
      with-predictable-random [0], null, ->
        helper = new GeneHelperBuilder base: 3, codon-bits: 2 .build()
        bits = '00010210'
        helper.mutate-point bits .should.not.eql bits

