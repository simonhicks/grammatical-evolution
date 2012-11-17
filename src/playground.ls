_ = require \underscore

## genetic-helpers.ls
function random(limit)
  Math.floor(Math.random() * limit)

class GeneticHelper
  BASE = 2 # FIXME make base configurable (ie. write a decent flip-bit for BASE != 2)
  ({@codon-bits=8, @p-cross=0.3}:opts={}) ->

  ints-to-bits: (ints) ~>
    ljust = (s) ~> ('0' * (@codon-bits - s.length)) + s
    binary-strings = _.map ints, (it) -> ljust(it.to-string(BASE))
    binary-strings.join ''

  bits-to-ints: (bits) ~>
    bit-array = bits.split('')
    ints = []
    while bit-array.length > 0
      section = []
      _.times @codon-bits, ~>
        section.push bit-array.shift()
      section |> (-> it.join '') |> parse-int(_, BASE) |> ints.push
    ints

  flip-bit: (bit) ~>
    1 .^. parse-int(bit, BASE)

  point-mutation: (bits) ~>
    child = _.map bits, (bit) ~>
      if Math.random() < (1.0/bits.length) then @flip-bit bit else bit # FIXME make the `(1.0/bits.length)` configurable 
    child.join ''

  one-point-crossover: (parent1, parent2) ~>
    if (Math.random() < @p-cross)
      p1-ints = @bits-to-ints parent1
      p2-ints = @bits-to-ints parent2
      cut = random _.min [p1-ints.length, p2-ints.length]
      @ints-to-bits p1-ints[0 til cut].concat(p2-ints.slice(cut))
    else
      _.clone parent1

  codon-duplication: (bits) ->
    if Math.random() < (0.5/@codon-bits) # FIXME make the `(0.5/@codon-bits)` configurable 
      ints = @bits-to-ints bits
      i = random(ints.length)
      ints.push ints[i]
      @ints-to-bits ints
    else
      _.clone bits

  # TODO codon-deletion: (bits) ->
  #   # delete a random codon

  # TODO reproduce: (selected, population-size) ->
  #   # produce `population-size` bitstrings using pairs of strings from `selected`

  # TODO random-bitstring


## code-builder.ls
vm = require \vm

# TODO find a way to make this configurable... class variables are NOT the answer!
#   - STEP 1 - change CodeBuilder into a 'TranslatorBuilder' which closes over the configuration variables and returns a function that converts bit-strings to code-strings
#   - STEP 2 - change TranslatorBuilder into a 'SpeciesBuilder which does the same as above but returns a mixin which knows how to reproduce etc. using a genetics-helper instance as a c-var
#   - That mixin can then be mixed in to essentially dummy classes :)

function gsub(str, target, func)
  words = _.compact str.split(/\s+/)
  res = ''
  for word in words
    if word is target
      res := "#res #{func word}"
    else
      res += " #word"
  res

class CodeBuilder
  @min-depth = 2
  @max-depth = 7
  @grammar =
    S:    \EXP
    EXP:  [' FUNC ( EXP , EXP ) ', 'VAR']
    FUNC: <[ add sub div mul ]>
    VAR:  <[ x 1.0 ]>

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

  (integers) ->
    [done, offset, depth] = [false, 0, 0]
    symbolic-string = @@grammar[\S]
    do
      done := true
      _.chain(@@grammar).keys().each (key) ~>
        symbolic-string := gsub symbolic-string, key, (k) ~>
          done := false
          set = if (k is \EXP and depth >= (@@max-depth - 1)) then @@grammar[\VAR] else @@grammar[k]
          var next
          do
            integer = integers[offset] % set.length
            offset := if (offset == integers.length - 1) then 0 else offset + 1
            next = set[integer]
          until depth > @@min-depth or next isnt 'VAR'
          next
      depth++
    until done
    @code = "#{@@function-definitions}\n\n#symbolic-string"


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


## TEST AREA -- dummy impls for game and bot

#class Bot
  #@last-id = 0
  #({@id = ++@@last-id, @code}) ->

#class Game
  #@play = (bot1, bot2, opts) ->
    #instance = new Game bot1, bot2, opts
    #instance.play()
    #instance.get-winner()

  #(@bot1, @bot2, {@function,@min-input,@max-input}) ->

  #get-input: ->
    #@x ?= Math.floor(Math.random() * (@max-input - @min-input)) + @min-input

  #get-context: ->
    #@context ?= vm.create-context do
      #x: @get-input()

  #_run-code: (code) ->
    #vm.run-in-context code, @get-context()

  #winner: (target, val1, val2) ->
    #| val1 == val2 => false
    #| val1 < val2  => @bot1.id
    #| val2 < val1  => @bot2.id

  #play: ->
    #@target = @function @get-input()
    #@val1 = Math.abs(@target - @_run-code @bot1.code)
    #@val2 = Math.abs(@target - @_run-code @bot2.code)

  #get-winner: ->
    #@winner @target, @val1, @val2

#random-bot = (id) ->
  #ints = []
  #_.times 20, ->
    #ints.push Math.floor(Math.random() * 128)
  #code = new CodeBuilder ints .code
  #new Bot code: code, id: id


#opts =
  #function: (x) -> x**2 + x + 1
  #rounds: 10
  #max-input: 10
  #min-input: 1

#bots =
  #* random-bot \andy
  #* random-bot \bill
  #* random-bot \cath
  #* random-bot \duke
  #* random-bot \eddy
  #* random-bot \fred
  #* random-bot \gail
  #* random-bot \hall

#results = Tournament.run do
  #bots: bots
  #game-options: opts

#console.log _.map results, (.id)

