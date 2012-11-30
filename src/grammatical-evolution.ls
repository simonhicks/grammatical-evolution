

{exports.SpeciesBuilder} = require './grammatical-evolution/species-builder'
{exports.Tournament} = require './grammatical-evolution/tournament'

# add helper objects to the `util` namespace
util = {}
{util.Grammar} = require './grammatical-evolution/grammar'
{util.GeneHelperBuilder} = require './grammatical-evolution/gene-helper-builder'
{util.AlgorithmFactory} = require './grammatical-evolution/algorithm-factory'
exports.util = util
