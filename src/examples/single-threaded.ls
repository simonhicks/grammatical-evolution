vm = require 'vm'
_ = require \underscore
{SpeciesBuilder} = require '../grammatical-evolution'

# create a species using a basic arithmetic grammar
species-builder = new SpeciesBuilder do
  grammar:
    rules:
      S: ['EXP']
      EXP: ['(EXP OP EXP)', 'EXP OP EXP', 'VAR']
      OP: <[ * / + - ]>
      VAR: <[ x 1 ]>
    max-depth: 7
    min-depth: 2
  children-per-couple: 2
  genetics:
    codon-bits: 4

Species = species-builder.build-species()


# create a competition class... in this case the target is to approximate a simple polynomial
class FunctionApproximationFitnessCalculator
  ({@comparisons, @function, @max-input, @min-input, @invalid-penalty=99999999}) ->

  calculate-error: (bot) ~>
    total-error = 0
    _.times @comparisons, ~>
      x = @random-input()
      target = @function x
      result = vm.runInNewContext(bot.get-code(), {x: x})
      error =
        | result is null              => @invalid-penalty
        | typeof result is \undefined => @invalid-penalty
        | not isFinite result         => @invalid-penalty
        | otherwise                   => Math.abs(target - result)
      total-error += error
    bot.error = total-error / @comparisons

  # return a random value for x within the specified bounds
  random-input: ~>
    @min-input + Math.random() * (@max-input - @min-input)

comparator = new FunctionApproximationComparator do
  comparisons: 30
  function: (x) -> x**4 + x**3 + x**2 + x
  max-input: 10
  min-input: 1


# create some utility functions for later
function random-nth(coll)
  i = Math.floor(Math.random() * coll.length)
  coll[i]


function get-lowest-error(bots)
  sorted = _.sort-by(bots, (.error))
  sorted[0]


best = {error: 99999999}
function update-fitnesses(population)
  for bot in population
    comparator.calculate-error bot
  winner = get-lowest-error(population)
  best := if best.error < winner.error then best else winner


function binary-tournament(population)
  [b1, b2] = [random-nth(population), random-nth(population)]
  if b1.error < b2.error then b1 else b2


# basic parameters
generation-size = 100
number-of-generations = 50

# initial state
population = [Species.create() for i from 1 to generation-size]
generation = 1
parents = []

while generation <= number-of-generations
  update-fitnesses population
  console.log "Generation #generation : err=#{best.error} : code='#{best.get-code().replace(/\n/g, '')}'"

  break if best.error < 1e-10

  until parents.length is generation-size * 2
    selected = binary-tournament population
    parents.push(selected)

  population = Species.match(parents)
  parents := []
  generation++

update-fitnesses population
console.log "Generation #generation : err=#{best.error} : code='#{best.get-code().replace(/\n/g, '')}'"
