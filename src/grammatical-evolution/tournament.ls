_ = require \underscore

class exports.Tournament
  @create-factory = (opts) ->
    new
      create: (bots) ->
        _opts = _.clone(opts)
        _opts.competitors = bots
        new Tournament _opts

      play: (bots) ->
        t = @create bots
        t.play()
        t.get-winners()


  # competitors is an array of objects, each with a code attribute and a unique id
  # gameFunction is a Function which takes 2 competitors and returns the id of the 'fitter' one
  # rounds is the number of times each bot plays each other bot
  ({@competitors, @game-function, @rounds=5, @number-of-competitors, @number-of-winners}:opts={}) ->
    @_validate-mandatory-arg(\gameFunction)
    @_validate-mandatory-arg(\competitors)
    @_validate-competitors()
    @_points = {}


  _validate-mandatory-arg: (field-name) ->
    unless @[field-name]?
      throw new Error "Missing mandatory arg #field-name"


  _validate-competitors: ->
    unless @competitors.length > 1
      throw new Error "Invalid configuration. Please supply at least 2 competitors"

    unless _.all(@competitors, (c) -> _.has(c, \getId) and _.has(c, \getCode))
      throw new Error "Invalid configuration. Competitors require `getId` and `getCode` methods"

    if @number-of-competitors? and @competitors.length > @number-of-competitors
      @competitors = _.chain(@competitors).shuffle().take(@number-of-competitors).value()

  _play-match: (bot1, bot2) ~>
    @game-function(bot1, bot2) |> @_award-point

  _award-point: (winner) ~>
    @_points[winner] ?= 0
    @_points[winner]++

  _get-points: (bot) ~>
    id = bot.get-id()
    @_points[id]

  _play-round: ~>
    [@_play-match(bot1, bot2) for bot1, i1 in @competitors for bot2, i2 in @competitors when i1 < i2]

  play: ->
    _.times @rounds, @_play-round

  get-results: ~>
    _.sort-by @competitors, @get-points .reverse()

  get-winners: (n=@number-of-winners) ->
    _.take @get-results(), n
