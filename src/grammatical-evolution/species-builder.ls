_ = require \underscore
uuid = require \node-uuid
{Grammar} = require './grammar'
{GeneHelperBuilder} = require './gene-helper-builder'
{AlgorithmFactory} = require './algorithm-factory'


class exports.SpeciesBuilder
  ({@children-per-couple=2}:opts={}) ->
    @algorithm-factory = create-algorithm-factory(opts)
    @gene-helper = create-gene-helper(opts)
    validate-children-per-couple @children-per-couple


  # returns a Species object which essentially acts as a Factory for algorithms for use in grammatical
  # evolution GP.
  #
  # the returned Species object exposes a create() method which returns objects with the following
  # interface:
  # 
  # .get-genome()   : a string of bits that acts as the genome for the algorithm
  # .get-code()     : the string of code which the genome expands to within the configured grammar.
  # .screw(partner) : a new object with the same interface as this one, which represents the offspring
  #                   of this object and `partner`
  #
  build-species: ->
    algorithm-factory = _.clone @algorithm-factory
    gene-helper = _.clone @gene-helper
    children-per-couple = @children-per-couple
    create-critter = (bits) ->
      code = algorithm-factory.build gene-helper.bits-to-ints(bits)
      id = uuid.v4() # random unique id
      return new
        get-genome: -> bits
        get-code: -> code
        get-id: -> id
        screw: (partner) ->
          gene-helper.reproduce(bits, partner.get-genome()) |> create-critter

    return new
      create: ->
        create-critter(gene-helper.random-bitstring())

      match: (parents) ~>
        mixed = _.shuffle parents
        kids = []
        for dad, i in mixed by 2
          mum = mixed[i + 1]
          _.times children-per-couple, -> kids.push(dad.screw(mum))
        kids


  # utility functions (ie. "private" methods)
  function isnt-whole-number(n)
    (n %% 1) isnt 0


  function validate-children-per-couple(n)
    if isnt-whole-number n
      throw new Error "Invalid argument: childrenPerCouple should be an integer"


  function create-algorithm-factory({grammar,postfix-code,prefix-code,wrapper-function}:opts)
    grammar = create-grammar opts
    new AlgorithmFactory do
      grammar: grammar
      postfix-code: postfix-code
      prefix-code: prefix-code
      wrapper-function: wrapper-function


  function create-grammar({grammar})
    unless grammar?
      throw new Error "Missing mandatory arg grammar: you must either pass a Grammar instance or the configuration settings for one"

    if grammar.constructor is Grammar
      grammar
    else
      new Grammar grammar


  function create-gene-helper({genetics})
    new GeneHelperBuilder(genetics).build()
