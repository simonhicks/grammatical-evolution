_ = require \underscore


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

# FIXME these should be rebuilt using the new impls
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
