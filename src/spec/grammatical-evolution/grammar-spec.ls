should = require \should
_ = require \underscore

{Grammar} = require '../../grammatical-evolution/grammar'

suite 'Grammar', ->
  setup ->
    @assert-expandables = (grammar, expandables) ->
      _.select(grammar.keys, grammar.is-expandable).should.eql expandables

    @assert-terminals = (grammar, terminals) ->
      _.select(grammar.keys, grammar.is-terminal).should.eql terminals

  suite 'when fetching the starting point options', ->
    test 'the starting point should be available via #initial-options()', ->
      rules =
        S: <[ EXP ]>
        EXP: ['FUNC(EXP, EXP)', 'VAR']
        FUNC: <[ add sub div mul ]>
        VAR: <[ x 1.0 ]>
      grammar = new Grammar rules
      grammar.initial-options().should.eql rules[\S]


  suite 'a key is expandable if', ->
    test 'it contains an expression that matches more than one key', ->
      grammar = new Grammar do
        S: <[ EXP ]>
        EXP: ['FUNC(EXP, EXP)', 'VAR']
        FUNC: <[ add sub div mul ]>
        VAR: <[ x 1.0 ]>
      @assert-expandables grammar, <[ S EXP ]>

    test 'it contains an expression that expands to something that matches an expandable key', ->
      grammar = new Grammar do
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


  suite "a key isn't expandable if", ->
    test "it's expressions don't match any keys", ->
      grammar = new Grammar do
        S: <[ EXP ]>
        EXP: ['FUNC(EXP, EXP)', 'VAR']
        FUNC: <[ add sub div mul ]>
        VAR: <[ x 1.0 ]>
      @assert-expandables grammar, <[ S EXP ]>

    test "it's expressions match only one key, which isn't expandable", ->
      grammar = new Grammar do
        S: <[ EXP ]>
        EXP: ['FUNC(EXP, EXP)', 'VAR']
        FUNC: <[ add sub div mul ]>
        VAR: <[ INPUT CONST ]>
        INPUT: <[ x y ]>
        CONST: <[ 1 2 3]>
      @assert-expandables grammar, <[ S EXP ]>


  suite 'a key is terminal if', ->
    test "it can't expand to another key and it's a valid expression on it's own", ->
      grammar = new Grammar do
        S: <[ EXP ]>
        EXP: ['FUNC(EXP, EXP)', 'VAR']
        FUNC: <[ add sub div mul ]>
        VAR: <[ x 1 ]>
      @assert-terminals grammar, <[ VAR ]>

    test "it only expands to other terminal keys", ->
      grammar = new Grammar do
        S: <[ EXP ]>
        EXP: ['FUNC(EXP, EXP)', 'VAR']
        FUNC: <[ add sub div mul ]>
        VAR: <[ INPUT CONST ]>
        INPUT: <[ x y ]>
        CONST: <[ 1 2 3]>
      @assert-terminals grammar, <[ VAR INPUT CONST ]>


  suite 'a grammar is invalid if', ->
    test "it doesn't contain the starting key `S`", ->
      invalid = ->
        new Grammar do
          EXP: ['FUNC(EXP, EXP)', 'VAR']
          FUNC: <[ add sub div mul ]>
          VAR: <[ x 1.0 ]>
      invalid.should.throw-error /invalid grammar/i
      invalid.should.throw-error /\bS\b/
      invalid.should.throw-error /missing mandatory starting key/

    test "starting key S isn't expandable", ->
      invalid = ->
        new Grammar do
          S: <[ VAR ]>
          EXP: ['FUNC(EXP, EXP)', 'VAR']
          FUNC: <[ add sub div mul ]>
          VAR: <[ x 1.0 ]>
      invalid.should.throw-error /invalid grammar/i
      invalid.should.throw-error /\bS\b/
      invalid.should.throw-error /not expandable/i

    test 'it contains a key that expands directly to itself', ->
      invalid = ->
        new Grammar do
          S: <[ EXP ]>
          EXP: <[ EXP VAR ]>
          VAR: <[ 1 ]>
      invalid.should.throw-error /EXP/
      invalid.should.throw-error /invalid grammar/i

    test 'if contains a key that expands indirectly to itself', ->
      invalid = ->
        new Grammar do
          S: <[ EXP ]>
          EXP: <[ EXP2 VAR ]>
          EXP2: <[ EXP VAR ]>
          VAR: <[ x 1 ]>
      invalid.should.throw-error /EXP/
      invalid.should.throw-error /invalid grammar/i

  suite 'fetching options for expressions', ->
    suite 'when not too deep or too shallow', ->
    suite 'when too deep', ->
    suite 'when too shallow', ->
