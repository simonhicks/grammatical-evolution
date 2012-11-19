_ = require \underscore

{Grammar} = require './grammatical-evolution/grammar'

## code-builder.ls
vm = require \vm

class CodeBuilder
  @min-depth = 2
  @max-depth = 7

  # the grammar should obey the following rules:
  # - it should have exactly one key \S, with one value representing an expression. This is the root of the AST and will be the starting point for all expansions.
  # - no higher order functions are allowed # FIXME is this still true??
  @grammar =
    S:    \EXP
    EXP:  ['FUNC(EXP, EXP)', 'VAR']
    FUNC: <[ add sub div mul ]>
    VAR:  <[ x 1.0 ]>

  # the keys which represent a terminal (ie. something which can't be expanded any further and is an expression in it's own right.)
  @terminal-keys = <[ VAR ]>

  # the keys which represent an expandable expression.
  @expandable-keys = <[ EXP ]>

  @function-definitions = '''
    function add(a, b) {
      return a + b;
    }

    function sub(a, b) {
      return a - b;
    }

    function div(a, b) {
      if (b === 0) {
        return a;
      } else {
        return a / b;
      }
    }

    function mul(a, b) {
      return a * b;
    }
  '''

  (@integers) ->
    [@offset, @depth] = [0, 0]
    @symbolic-string = @@grammar[\S]
    do
      @expand-keys()
    until @finished()
    @code = "#{@@function-definitions}\n\n#{@symbolic-string};"

  expand-keys: ->
    _.chain(@@grammar).keys().each (key) ~> @expand-key key
    @depth++

  expand-key: (key) ->
    @symbolic-string := @symbolic-string.replace new RegExp(key, 'g'), @expansion-for-key

  # returns the next expansion for `key` by selecting the nth item from cycling through `key`s value in `@grammar` (where n is the next int from `@integers`)
  expansion-for-key: (key) ~>
    options = @options-for-key(key)
    index = @next-integer() % options.length
    options[index]

  next-integer: ->
    i = @integers[@offset]
    @increment-offset()
    i

  increment-offset: ->
    @offset = if (@offset == @integers.length - 1) then 0 else @offset + 1

  finished: ->
    patterns = _.chain @@grammar .keys!.map(-> new RegExp(it)).value()
    not _.any patterns, ~> it.test(@symbolic-string)

  ## returns true if `key` can't be expanded any further
  #is-terminal: (key) ~>
    #keys = _.keys(@@grammar)
    #_.contains(keys, key) && not @is-expandable key

  ## returns true if `str` can be expanded further (in other words if it contains any expandable keys)
  #is-expandable: (str) ~>
    #_.any @@expandable-keys, -> str.match it

  ## the possible expansions for `key`, taken from `@@grammar`.
  #options-for-key: (key) ->
    #@@grammar[key] |> @filter-for-depth # FIXME move this logic into Grammar & add something to make sure this result isn't empty

  ## filters the list of possible expressions to ensure we don't stop expanding until we reach a certain depth, but stop before the expression is too deep.
  #filter-for-depth: (options) ~>
    #| @depth < @@min-depth => _.reject options, @is-terminal
    #| @depth > (@@max-depth - 1) => _.reject options, @is-expandable
    #| otherwise => options


## tournament.ls

# FIXME this required some changes from the version in fruithunt... figure out why
# TODO move this from fruithunt into this module
# TODO make the Game class configurable
#  - document the interface that Game is expected to fulfil
#  - figure out how to handle the expected type for 'bots'... maybe Game needs to be able to validate a competitor
class Tournament
  @DEFAULT_ROUNDS = 10

  @run = (opts) ->
    instance = new this(opts)
    instance.play()
    res = _.sort-by(instance.get-bots(), ({id}) -> instance.get-wins(id)).reverse()
    instance.get-results()

  ({@bots,@rounds,@game-options}) ->
    @_points = {}
    @_validate-bots()
    @_validate-rounds()

  _validate-bots: ->
    if not @bots?
      @_missing-arg \bots
    else if @bots.length < 2
      @_invalid-arg 'bots', 'must contain at least 2 bots'
    else if ! _.all(@bots, -> it.constructor == Bot)
      @_invalid-arg 'bots', 'should only contain instances of Bot'

  _validate-rounds: ->
    @rounds ?= @@DEFAULT_ROUNDS

  get-bots: -> @bots

  get-wins: (id) ->
    @_points[id] ? 0

  _missing-arg: (field) ->
    throw new Error "Missing mandatory arg #field"

  _invalid-arg: (field, msg) ->
    throw new Error "Invalid arg #field. #field #msg."

  _play-match: (bot1, bot2) ~>
    Game.play(bot1, bot2, @game-options) |> @_award-point

  _award-point: (winner) ~>
    @_points[winner] ?= 0
    @_points[winner]++

  _play-round: ~>
    [@_play-match(bot1, bot2) for bot1, i1 in @bots for bot2, i2 in @bots when i1 < i2]

  play: ->
    _.times @rounds, @_play-round

  get-results: ->
    _.sort-by(@get-bots(), ({id}) ~> @get-wins(id)).reverse()


# TEST AREA -- dummy impls for game and bot

class Bot
  @last-id = 0
  ({@id = ++@@last-id, @code}) ->

class Game
  @play = (bot1, bot2, opts) ->
    instance = new Game bot1, bot2, opts
    instance.play()
    instance.get-winner()

  (@bot1, @bot2, {@function,@min-input,@max-input}) ->

  get-input: ->
    @x ?= Math.floor(Math.random() * (@max-input - @min-input)) + @min-input

  get-context: ->
    @context ?= vm.create-context do
      x: @get-input()

  _run-code: (code) ->
    vm.run-in-context code, @get-context()

  winner: (target, val1, val2) ->
    | val1 == val2 => false
    | val1 < val2  => @bot1.id
    | val2 < val1  => @bot2.id

  play: ->
    @target = @function @get-input()
    @val1 = Math.abs(@target - @_run-code @bot1.code)
    @val2 = Math.abs(@target - @_run-code @bot2.code)

  get-winner: ->
    @winner @target, @val1, @val2

random-bot = (id) ->
  ints = []
  _.times 20, ->
    ints.push Math.floor(Math.random() * 128)
  code = new CodeBuilder ints .code
  console.log code
  new Bot code: code, id: id


opts =
  function: (x) -> x**2 + x + 1
  rounds: 10
  max-input: 10
  min-input: 1

bots =
  * random-bot \andy
  * random-bot \bill
  * random-bot \cath
  * random-bot \duke
  * random-bot \eddy
  * random-bot \fred
  * random-bot \gail
  * random-bot \hiro

results = Tournament.run do
  bots: bots
  game-options: opts

console.log _.map results, (.id)

