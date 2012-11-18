should = require \should
_ = require \underscore

{Grammar} = require '../../grammatical-evolution/grammar'

suite 'Grammar', ->
  setup ->
    @assert-expandables = (grammar, expandables) ->
      _.select(grammar.keys, grammar.is-expandable).should.eql expandables

    @args = (rules) ->
      rules: rules
      max-depth: 7
      min-depth: 2

  suite 'when being configured', ->
    test 'should require a set of rules', ->
      invalid = ~>
        new Grammar @args(null)
      invalid.should.throw-error /\brules\b/

    test 'should have a default max-depth and min-depth', ->
      no-depths = ~>
        new Grammar do
          rules:
            S: <[ EXP ]>
            EXP: ['FUNC(EXP, EXP)', 'VAR']
            FUNC: <[ add sub div mul ]>
            VAR: <[ x 1.0 ]>
      no-depths.should.not.throw-error()
      no-depths().should.have.property 'maxDepth', 7
      no-depths().should.have.property 'minDepth', 2


  suite 'when fetching the starting point options', ->
    test 'the starting point should be available via #initial-options()', ->
      rules =
        S: <[ EXP ]>
        EXP: ['FUNC(EXP, EXP)', 'VAR']
        FUNC: <[ add sub div mul ]>
        VAR: <[ x 1.0 ]>
      grammar = new Grammar @args(rules)
      grammar.initial-options().should.eql rules[\S]


  suite 'a key is expandable if', ->
    test 'it contains an expression that matches more than one key', ->
      grammar = new Grammar @args do
        S: <[ EXP ]>
        EXP: ['FUNC(EXP, EXP)', 'VAR']
        FUNC: <[ add sub div mul ]>
        VAR: <[ x 1.0 ]>
      @assert-expandables grammar, <[ S EXP ]>

    test 'it contains an expression that expands to something that matches an expandable key', ->
      grammar = new Grammar @args do
        S: <[ EXP ]>
        EXP: <[ MONOCALL BINCALL VAR ]>
        MONOCALL: ['MONOFUNC(EXP)', 'MONOOP EXP']
        MONOFUNC: <[ f g ]>
        MONOOP: <[ + - ]>
        BINCALL: ['BINFUNC(EXP, EXP)', 'EXP BINOP EXP']
        BINFUNC: <[ div mult ]>
        BINOP: <[ + - ]>
        VAR: <[ x y 1 ]>
      @assert-expandables grammar, <[ S EXP MONOCALL BINCALL ]>


  suite 'an expression is expandable if', ->
    setup ->
      @grammar = new Grammar @args do
        S: <[ return EXP ]>
        EXP: ['FUNC(VAR, VAR)', 'VAR']
        FUNC: <[ add sub div mul ]>
        VAR: <[ x 1 ]>

    test 'it contains more than one key', ->
      @grammar.is-expandable 'FUNC(VAR, VAR)' .should.equal true

    test 'it contains an expandable key', ->
      @grammar.is-expandable 'return EXP' .should.equal true


  suite "a key isn't expandable if", ->
    test "it's expressions don't match any keys", ->
      grammar = new Grammar @args do
        S: <[ EXP ]>
        EXP: ['FUNC(EXP, EXP)', 'VAR']
        FUNC: <[ add sub div mul ]>
        VAR: <[ x 1.0 ]>
      @assert-expandables grammar, <[ S EXP ]>

    test "it's expressions match only one key, which isn't expandable", ->
      grammar = new Grammar @args do
        S: <[ EXP ]>
        EXP: ['FUNC(EXP, EXP)', 'VAR']
        FUNC: <[ add sub div mul ]>
        VAR: <[ INPUT CONST ]>
        INPUT: <[ x y ]>
        CONST: <[ 1 2 3 ]>
      @assert-expandables grammar, <[ S EXP ]>


  suite 'a grammar is invalid if', ->
    test "it doesn't contain the starting key `S`", ->
      invalid = ~>
        new Grammar @args do
          EXP: ['FUNC(EXP, EXP)', 'VAR']
          FUNC: <[ add sub div mul ]>
          VAR: <[ x 1.0 ]>
      invalid.should.throw-error /invalid grammar/i
      invalid.should.throw-error /\bS\b/
      invalid.should.throw-error /missing mandatory starting key/

    test "starting key S isn't expandable", ->
      invalid = ~>
        new Grammar @args do
          S: <[ VAR ]>
          EXP: ['FUNC(EXP, EXP)', 'VAR']
          FUNC: <[ add sub div mul ]>
          VAR: <[ x 1.0 ]>
      invalid.should.throw-error /invalid grammar/i
      invalid.should.throw-error /\bS\b/
      invalid.should.throw-error /not expandable/i

    test 'it contains a key that expands directly to itself', ->
      invalid = ~>
        new Grammar @args do
          S: <[ EXP ]>
          EXP: <[ EXP VAR ]>
          VAR: <[ 1 ]>
      invalid.should.throw-error /EXP/
      invalid.should.throw-error /invalid grammar/i

    test 'if contains a key that expands indirectly to itself', ->
      invalid = ~>
        new Grammar @args do
          S: <[ EXP ]>
          EXP: <[ EXP2 VAR ]>
          EXP2: <[ EXP VAR ]>
          VAR: <[ x 1 ]>
      invalid.should.throw-error /EXP/
      invalid.should.throw-error /invalid grammar/i

  suite 'fetching options for expressions', ->
    setup ->
      @opts =
        rules:
          S: <[ EXP ]>
          EXP: ['FUNC(EXP, EXP)', 'VAR']
          FUNC: <[ add sub div mul ]>
          VAR: <[ INPUT NUMBER ]>
          INPUT: <[ x y ]>
          NUMBER: <[ 1 2 3 ]>
        max-depth: 7
        min-depth: 2
      @create-instance = -> new Grammar @opts

    test 'when not too deep or too shallow', ->
      instance = @create-instance()
      instance.get-options-for(\EXP, 5).should.eql @opts.rules.EXP

    test 'when too deep', ->
      instance = @create-instance()
      expected = _.reject @opts.rules.EXP, -> instance.is-expandable(it)
      instance.get-options-for(\EXP, 7).should.eql expected

    test 'when too shallow', ->
      instance = @create-instance()
      expected = _.select @opts.rules.EXP, -> instance.is-expandable(it)
      instance.get-options-for(\EXP, 1).should.eql expected
