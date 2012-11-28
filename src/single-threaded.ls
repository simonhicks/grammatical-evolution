vm = require 'vm'
_ = require \underscore
{SpeciesBuilder} = require './grammatical-evolution/species-builder'
{Tournament} = require './grammatical-evolution/tournament'
{Cupid} = require './grammatical-evolution/cupid'

species-builder = new SpeciesBuilder do
  grammar:
    rules:
      S: ['EXP']
      EXP: ['(EXP OP EXP)', 'EXP OP EXP', 'VAR']
      OP: <[ * / + - ]>
      VAR: <[ x 1 ]>
    max-depth: 7
    min-depth: 2
  genetics:
    base: 2
    codon-bits: 4

Species = species-builder.build-species()


# create a competition class... in this case the target is to approximate a simple polynomial
class FunctionApproximationComparator
  ({@comparisons, @function, @max-input, @min-input, @invalid-penalty=99999999}) ->

  get-error: (bot) ~>
    x = @random-input()
    target = @function x
    result = vm.runInNewContext(bot.get-code(), {x: x})
    error =
      | result is null              => @invalid-penalty
      | typeof result is \undefined => @invalid-penalty
      | not isFinite result         => @invalid-penalty
      | otherwise                   => Math.abs(target - result)
    return error

  # return a random value for x within the specified bounds
  random-input: ~>
    @min-input + Math.random() * (@max-input - @min-input)

  calculate-fitness: (bots) ~>
    for bot in bots
      error = 0
      _.times @comparisons, ~>
        error += @get-error bot
      bot.error = error / @comparisons

comparator = new FunctionApproximationComparator do
  comparisons: 30
  function: (x) -> x**4 + x**3 + x**2 + x
  max-input: 10
  min-input: 1

cupid = new Cupid children-per-couple: 2

# create some utility functions for later
function random-int(max)
  Math.floor(Math.random() * max)

function random-nth(coll)
  coll[random-int coll.length]

function choose-n(n, coll)
  [random-nth(coll) for i from 1 to n]

function get-best(bots)
  sorted = _.sort-by(bots, (.error))
  sorted[0]


# basic parameters
generation-size = 100
number-of-generations = 50

# initial state
population = [Species.create() for i from 1 to generation-size]
generation = 1
parents = []


best = {error: 99999999}
while generation <= number-of-generations
  comparator.calculate-fitness(population)
  winner = get-best(population)
  best = if best.error < winner.error then best else winner
  console.log "Generation #generation : err=#{best.error} : code='#{best.get-code().replace(/\n/g, '')}'"

  until parents.length is generation-size * 2
    [b1, b2] = [random-nth(population), random-nth(population)]
    parents.push(if b1.error < b2.error then b1 else b2)

  population = cupid.match(parents)
  parents := []
  generation++

comparator.calculate-fitness(population)
console.log "AFTER: #{get-best(population).error}"
