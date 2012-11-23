should = require \should
_ = require \underscore

{Tournament} = require '../../grammatical-evolution/tournament'

suite 'Tournament', ->
  setup ->
    @min-opts =
      game-function: (b1, b2) -> b1.get-id()
      competitors:
        * get-id: -> '1'
          get-code: -> '1'
        * get-id: -> '2'
          get-code: -> '2'

    @create-tournament = (opts) ~>
      new Tournament _.extend({}, @min-opts, opts)

  suite 'when being created', ->
    test 'requires a collection of objects to use as competitors', ->
      @create-tournament.should.not.throw-error()

      @min-opts.competitors.shift()
      @create-tournament.should.throw-error /\bcompetitors\b/

      @min-opts.competitors = null
      @create-tournament.should.throw-error /\bcompetitors\b/
      @create-tournament.should.throw-error /missing mandatory arg/i


    test "requires competitors to have get-id and a get-code methods", ->
      @min-opts.competitors =
        * get-code: -> '1'
        * get-code: -> '2'
      @create-tournament.should.throw-error /\bgetId\b/

      @min-opts.competitors =
        * get-id: -> '1'
        * get-id: -> '2'
      @create-tournament.should.throw-error /\bgetCode\b/


    suite 'when selecting competitors', ->
      setup ->
        @competitors =
          * get-id: -> '1', get-code: -> '1'
          * get-id: -> '2', get-code: -> '2'
          * get-id: -> '3', get-code: -> '3'
          * get-id: -> '4', get-code: -> '4'
          * get-id: -> '5', get-code: -> '5'
          * get-id: -> '6', get-code: -> '6'
          * get-id: -> '7', get-code: -> '7'
          * get-id: -> '8', get-code: -> '8'


      test 'accepts an optional number-of-competitors arg', ->
        tournament = @create-tournament do
          number-of-competitors: 2
          competitors: @competitors
        tournament.competitors.should.have.length 2


      test 'randomly selects competitors when too many are passed in', ->
        tournament1 = @create-tournament number-of-competitors: 2, competitors: @competitors
        tournament2 = @create-tournament number-of-competitors: 2, competitors: @competitors
        get-ids = (tournament) -> _(tournament.competitors).map(-> it.get-id())
        get-ids(tournament1).should.not.eql get-ids(tournament2)


      test "doesn't apply a default number-of-competitors", ->
        # a tournament without a specific number-of-competitors should use all the competitors
        tournament1 = @create-tournament number-of-competitors: null, competitors: @competitors
        tournament1.competitors.should.have.length @competitors.length
        # changing the number of competitors given, should also change the number of competitors
        # accepted
        tournament2 = @create-tournament do
          number-of-competitors: null
          competitors: _.take(@competitors, 4)
        tournament2.competitors.should.have.length 4


    test "requires a game function to use as an individual competition between two competitors", ->
      @min-opts.game-function = null
      @create-tournament.should.throw-error /\bgameFunction\b/


    test "accepts a number of rounds as a configuration option", ->
      n = 10
      @min-opts.rounds = n
      @create-tournament.should.not.throw-error()
      @create-tournament().rounds.should.equal n


    test "has a default number of rounds", ->
      @min-opts.rounds = null
      @create-tournament.should.not.throw-error()
      @create-tournament().rounds.should.equal 5


  suite 'when playing', ->
    setup ->
      # set up state
      @bot = (ch) -> get-id: -> ch, get-code: -> "'#ch'"
      @opts =
        rounds: 3
        competitors:
          * @bot \a
          * @bot \b
          * @bot \c
          * @bot \d
        game-function: (...args) ~>
          @call-list ?= []
          @call-list.push args
          args.sort()[1].get-id()

      @tournament = new Tournament @opts

      # Helpers
      @assert-number-of-games-played = ~>
        # each bot plays each other bot twice...
        expected-games = @opts.rounds * _.reduce [@opts.competitors.length - 1 to 1 by -1], (+), 0
        @call-list.should.have.length expected-games

      @assert-result-order = (results) ~>
        # the bot with the alphabetically later id wins
        expected-order = _.map @opts.competitors, (-> it.get-id()) .reverse
        sorted-ids = _.map @tournament.results, (-> it.get-id())
        sorted-ids.should.eql expected-order


    test 'makes each bot play each other bot N times', ->
      @tournament.play()
      @assert-number-of-games-played()


    test 'ranks the bots in the order of the number of games they won', ->
      @tournament.play()
      @assert-result-order @tournament.get-results()


    suite 'when selecting winners', ->
      test 'accepts an optional number-of-winners arg', ->
        tournament = @create-tournament do
          number-of-winners: 2
          competitors:
            * @bot \a
            * @bot \b
            * @bot \c
            * @bot \d
        tournament.play()
        tournament.get-winners().should.have.length 2


      test "doesn't apply a default number-of-winners", ->
        tournament = @create-tournament do
          competitors:
            * @bot \a
            * @bot \b
            * @bot \c
            * @bot \d
        tournament.play()
        tournament.get-winners 2 .should.have.length 2
        tournament.get-winners 3 .should.have.length 3


  suite 'when producing repeatable Tournaments', ->
    setup ->
      # create a tournament factory
      @opts =
        rounds: 3
        number-of-winners: 2
        game-function: ->
      @bots =
        * get-id: -> \a
          get-code: -> "'a'"
        * get-id: -> \b
          get-code: -> "'b'"
        * get-id: -> \c
          get-code: -> "'c'"
      @factory = Tournament.create-factory @opts

    test 'exposes a create-factory(...) class method', ->
      # create some two factories with the same factory, but different bots
      bots1 = @bots
      t1 = @factory.create bots1
      bots2 =
        * get-id: -> \d
          get-code: -> "'d'"
        * get-id: -> \e
          get-code: -> "'e'"
        * get-id: -> \f
          get-code: -> "'f'"
      t2 = @factory.create bots2

      # both results should be Tournaments
      t1.should.be.an.instance-of Tournament
      t2.should.be.an.instance-of Tournament

      # the tournaments should have the right bots in them
      t1.competitors.should.eql bots1
      t2.competitors.should.eql bots2

      # both tournaments should have the same @opts as the original factory
      for key, value of @opts
        t1[key].should.equal value
        t2[key].should.equal value


    test 'the tournament factory exposes a play(...) method', ->
      @factory.play(@bots).should.have.length @opts.number-of-winners
