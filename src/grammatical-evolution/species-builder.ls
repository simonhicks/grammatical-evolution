_ = require \underscore
{Grammar} = require './grammar'
{GeneHelperBuilder} = require './gene-helper-builder'
{AlgorithmFactory} = require './algorithm-factory'

class exports.SpeciesBuilder
  (opts={}) ->
    @algorithm-factory = @_create-algorithm-factory(opts)
    @gene-helper = @_create-gene-helper(opts)

  _create-algorithm-factory: ({grammar,postfix-code,prefix-code}:opts) ->
    grammar = @_create-grammar opts
    new AlgorithmFactory grammar: grammar, postfix-code: postfix-code, prefix-code: prefix-code

  _create-grammar: ({grammar}) ->
    unless grammar?
      throw new Error "Missing mandatory arg grammar: you must either pass a Grammar instance or the configuration settings for one"

    if grammar.constructor is Grammar
      grammar
    else
      new Grammar grammar

  _create-gene-helper: ({genetics}) ->
    new GeneHelperBuilder(genetics).build()

  # returns a Species object which essentially acts as a Factory for algorithms for use in grammatical
  # evolution GP.
  #
  # the returned Species object exposes a create() method which returns objects with the following
  # interface:
  # 
  # .get-genome()  : a string of bits that acts as the genome for the algorithm
  # .get-code()    : the string of code which the genome expands to within the configured grammar.
  # .mate(partner) : a new object with the same interface as this one, which represents the offspring
  #                  of this object and `partner`
  build-species: ->
    algorithm-factory = _.clone @algorithm-factory
    gene-helper = _.clone @gene-helper

    function create-critter(bits)
      code = algorithm-factory.build gene-helper.bits-to-ints(bits)
      new
        get-genome: -> bits
        get-code: -> code
        screw: (partner) ->
          gene-helper.reproduce(bits, partner.get-genome()) |> create-critter

    new
      create: ->
        create-critter(gene-helper.random-bitstring())

