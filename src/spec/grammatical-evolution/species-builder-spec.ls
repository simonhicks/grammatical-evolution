should = require \should
_ = require \underscore

{SpeciesBuilder} = require '../../grammatical-evolution/species-builder'
{Grammar} = require '../../grammatical-evolution/grammar'
{GeneHelperBuilder} = require '../../grammatical-evolution/gene-helper-builder'

suite 'SpeciesBuilder', ->
  setup ->
    @valid-grammar-config =
        rules:
          S: ['FUNC(EXP, EXP)']
          EXP: <[ S VAR ]>
          FUNC: <[ add subtract multiply divide ]>
          VAR: <[ x 1 ]>

    @opts = grammar: @valid-grammar-config

    @create-builder = (opts) ~>
      new SpeciesBuilder _.extend({}, @opts, opts)


  suite 'when being configured', ->
    test 'accepts config for a grammar instance', ->
      @opts = grammar: @valid-grammar-config
      @create-builder.should.not.throw-error()

    test 'accepts a pre-existing Grammar instance', ->
      @create-builder.should.not.throw-error(grammar: new Grammar @valid-grammar-config)

    test 'requires either a Grammar instance or the grammar config', ->
      (~> @create-builder(grammar: null)).should.throw-error(/grammar/)

    test 'uses the created grammar object to construct an AlgorithmFactory', ->
      grammar = new Grammar @valid-grammar-config
      builder = @create-builder(grammar: grammar)
      builder.algorithm-factory.grammar.should.equal grammar

    test 'accepts prefix-code and postfix-code for the AlgorithmFactory', ->
      builder = @create-builder postfix-code: 'foo', prefix-code: 'bar'
      builder.algorithm-factory.postfix-code.should.equal 'foo'
      builder.algorithm-factory.prefix-code.should.equal 'bar'

    test "defaults to creating a default GeneHelper", ->
      builder = @create-builder()
      helper = builder.gene-helper
      default-helper = new GeneHelperBuilder().build()
      _.keys(helper).should.eql _.keys(default-helper)

    test 'uses GeneHelperBuilder config options to build the GeneHelper', ->
      @opts.genetics =
        base: 10
        codon-bits: 1
      @create-builder().gene-helper.bits-to-ints('01010101').should.eql [0, 1, 0, 1, 0, 1, 0, 1]

  suite 'builds a Species object', ->
    test 'which is independent of the original species-builder', ->
      builder = @create-builder()
      species = builder.build-species()

      # replace the algorithm-factory with a mock that will fail if used
      builder.algorithm-factory = new
        build: ->
          should.fail("Expected the species object to use the original algorithm factory")

      # perform an operation that would invoke the #build() method on the algorithm-factory
      species.create()

    suite '.create() returns an object', ->
      test 'with a bitstring that conforms to the gene-helper settings', ->
        builder = @create-builder do
          grammar: @valid-grammar-config
          genetics:
            base: 2
            codon-bits: 8
            number-of-codons: 10
        species = builder.build-species()
        critter = species.create()
        bitstring = critter.get-genome()
        bitstring.should.match /^[01]*$/
        bitstring.should.have.length 80

      test 'which uses the grammar rules to convert the bitstring to code', ->
        builder = @create-builder()
        species = builder.build-species()
        critter = species.create()
        critter.get-code().should.equal

      test 'which can screw another Species generated object to produce another similar object', ->
        builder = @create-builder()
        species = builder.build-species()
        mum = species.create()
        dad = species.create()
        kid = dad.screw(mum)
        kid.should.have-own-property 'getGenome'
        kid.should.have-own-property 'getCode'
        kid.should.have-own-property 'screw'

      test 'uses the gene-helper settings for reproduction', ->
        # create a species which allows no mutation and has a 100% chance of crossover
        builder = @create-builder do
          genetics:
            point-mutation-rate: 0
            crossover-rate: 10
            duplication-rate: 0
            deletion-rate: 0
        species = builder.build-species()

        # create a baby
        mum = species.create()
        dad = species.create()
        kid = dad.screw mum

        # check that baby's dna comes entirely from mum and dad
        _.each kid.get-genome(), (bit, i) ->
          from-parent = bit == mum.get-genome()[i] || bit == dad.get-genome()[i]
          from-parent.should.equal true

      test 'which is independent of the original builder', ->
        builder = @create-builder()
        species = builder.build-species()
        pre-existing = species.create()

        # replace the gene-helper with a mock that will fail if used
        builder.gene-helper = new
          reproduce: ->
            should.fail("Expected the original gene-helper to be used")

        # perform operations that will call the #reproduce(...) method on each critter object
        created-after = species.create()
        pre-existing.screw created-after
        created-after.screw pre-existing
