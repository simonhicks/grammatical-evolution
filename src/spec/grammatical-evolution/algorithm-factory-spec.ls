should = require \should

{AlgorithmFactory} = require '../../grammatical-evolution/algorithm-factory'
{Grammar} = require '../../grammatical-evolution/grammar'

suite 'AlgorithmFactory', ->

  suite 'when being configured', ->
    setup ->
      @min-opts =
        grammar: new Grammar do
          rules:
            S: ['FUNC(EXP, EXP)']
            EXP: <[ S VAR ]>
            FUNC: <[ add sub mul div ]>
            VAR: <[ x 1 ]>
      @create-instance = ->
        new AlgorithmBuilder @min-opts

    test 'requires a grammar argument', ->
      instance = @create-instance()
      @create-instance.should.not.throw-error
      instance.grammar.should.eql @min-opts.grammar
      @min-opts.grammar = null
      @create-instance.should.throw-error /mandatory arg/i
      @create-instance.should.throw-error /grammar/

    test 'takes an optional prefix code string', ->
      @min-opts.prefix-code = null
      @create-instance.should.not.throw-error
      @min-opts.prefix-code = 'var a = 1 + 1;'
      @create-instance.should.not.throw-error
      @create-instance().prefix-code.should.eql @min-opts.prefix-code

    test "has a default value of '' for prefix-code", ->
      @min-opts.prefix-code = null
      @create-instance().prefix-code.should.equal ''

    test 'takes an optional postfix code string', ->
      @min-opts.postfix-code = null
      @create-instance.should.not.throw-error
      @min-opts.postfix-code = 'var a = 1 + 1;'
      @create-instance.should.not.throw-error
      @create-instance().postfix-code.should.eql @min-opts.postfix-code

    test "has a default value of '' for postfix code", ->
      @min-opts.postfix-code = null
      @create-instance().postfix-code.should.equal ''
