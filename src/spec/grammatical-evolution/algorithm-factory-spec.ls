should = require \should

{AlgorithmFactory} = require '../../grammatical-evolution/algorithm-factory'
{Grammar} = require '../../grammatical-evolution/grammar'

suite 'AlgorithmFactory', ->
  setup ->
    @min-opts =
      grammar: new Grammar do
        rules:
          S: ['FUNC(EXP, EXP)']
          EXP: <[ S VAR ]>
          FUNC: <[ add sub mul div ]>
          VAR: <[ x 1 ]>
    @create-factory = ->
      new AlgorithmFactory @min-opts

  suite 'when being configured', ->
    @test-optional-argument = (field, dflt) ->
      test "takes an optional #field arg", ->
        @min-opts[field] = null
        @create-factory.should.not.throw-error
        @min-opts[field] = {}
        @create-factory.should.not.throw-error
        @create-factory()[field].should.eql @min-opts[field]

      test "has a default value of #dflt for #field", ->
        @min-opts[field] = null
        @create-factory()[field].should.equal dflt

    test 'requires a grammar argument', ->
      factory = @create-factory()
      @create-factory.should.not.throw-error
      factory.grammar.should.eql @min-opts.grammar
      @min-opts.grammar = null
      @create-factory.should.throw-error /mandatory arg/i
      @create-factory.should.throw-error /grammar/

    @test-optional-argument('prefixCode', '')
    @test-optional-argument('postfixCode', '')


  suite 'when building an algorithm', ->
    test 'should loop through the integers from a context object using @next-integer(state)', ->
      factory = @create-factory()
      context = integers: [1, 2, 3]
      ints = context.integers
      n = ints.length * 2 - 1
      [factory.next-integer(context) for i from 0 to n].should.eql ints.concat ints

    suite 'expansion-for-key(...)', ->
      test 'should choose the nth item from the appropriate list of exprs', ->
        # create a factory with a mock Grammar
        var received
        options = <[ one two ]>
        factory = new AlgorithmFactory do
          grammar:
            get-options-for: (key, depth) ->
              received := [key, depth]
              options

        # expect two loops through the options
        expected = options[0, 1, 0, 1]

        context = depth: 3 integers: [0, 1, 2, 3]
        [factory.expansion-for-key(context, \KEY) for i from 0 to 3].should.eql expected
        received.should.eql [\KEY, context.depth]

    suite 'expand-key(...)', ->
      test 'should replace the given key with the appropriate expansion from the Grammar', ->
        # create a factory with a mock Grammar
        rules = {BEFORE: [\AFTER1, \AFTER2], FOO: [\BAR]}
        factory = new AlgorithmFactory do
          grammar:
            get-options-for: (key, depth) -> rules[key]

        # set up the context
        context =
          integers: [0,1,2]
          depth: 0
          code: "BEFORE FOO BEFORE"
        factory.expand-key(context, \BEFORE)
        context.code.should.equal "AFTER1 FOO AFTER2"

    suite 'build(ints)', ->
      test 'should repeatedly replace the keys until there are none left (starting from S)', ->
        grammar = new Grammar do
          rules:
            S: ['FUNC(EXP, EXP)']
            EXP: <[ S VAR ]>
            FUNC: <[ add sub mul div ]>
            VAR: <[ x 1 ]>
          # let's ignore depth for now
          min-depth: 0
          max-depth: 1000
        factory = new AlgorithmFactory grammar: grammar

        # painstakingly setup the ints, so we have a known end state
        # NOTE. This test is VERY brittle
        ints =
          * 0 # replaces S with 'FUNC(EXP, EXP)'
            0 # replaces the first EXP with S => FUNC(S, EXP)
            1 # replaces the second EXP with VAR => FUNC(S, VAR)
            3 # replaces FUNC with `div` => div(S, VAR)
            4 # replaces VAR with `x` => div(S, x)
            7 # replaces S with FUNC(EXP, EXP) => div(FUNC(EXP, EXP), x)
            1 # replaces EXP with VAR => div(FUNC(VAR, EXP), x)
            1 # replaces EXP with VAR => div(FUNC(VAR, VAR), x)
            5 # replaces FUNC with `sub` => div(sub(VAR, VAR), x)
            1 # replaces VAR with `1` => div(sub(1, VAR), x)
            0 # replaces VAR with `x` => div(sub(1, x), x) => Finished!

        factory.build(ints).should.match(/div\(sub\(1, x\), x\)/)

  suite 'integration tests', ->
    setup ->
      @assert-factory = (factory) ->
        # using 10 sets of ints:
        # - ensure the builds are repeatable
        # - ensure they produce results with no KEYs, `undefined`s or `null`s
        # - unsure they product syntactically valid js

    test 'with a simple grammar'
    test 'with a more complex grammar'

    # TODO find a way to test the depth control
