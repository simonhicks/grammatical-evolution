should = require \should
_ = require \underscore

{Cupid} = require '../../grammatical-evolution/cupid'

suite 'Cupid', ->
  test 'requires an integer children-per-couple arg', ->
    (-> new Cupid children-per-couple: 1).should.not.throw-error()
    (-> new Cupid children-per-couple: 1.2).should.throw-error(/childrenPerCouple/)
    (-> new Cupid children-per-couple: null).should.throw-error(/childrenPerCouple/)


  suite 'when given a collection of bots', ->
    test 'matches the bots as parents and returns their children', ->
      function make-bot
        get-genome: -> '01010101010'
        get-code: -> 'console.log("whatever");'
        screw: (partner) ->
          @shags = if @shags? then @shags + 1 else 1
          partner.shags = if partner.shags? then partner.shags + 1 else 1
          {}

      parents = []
      _.times 10, ->
        parents.push make-bot()

      cupid = new Cupid children-per-couple: 2
      (kids = cupid.match(parents)).should.have.length(10)
      _.each parents, -> it.should.have.property \shags, 2

    test 'matches the bots randomly, and the pairs should remain monogamous', ->
      i = 0
      function make-bot
        id: i++
        get-genome: -> '01010101010101'
        get-code: -> 'console.log("whatever");'
        screw: (partner) ->
          (@partners ?= []).push partner.id
          (partner.partners ?= []).push @id

      parents = []
      _.times 10, ->
        parents.push make-bot()

      cupid = new Cupid children-per-couple: 7
      cupid.match(parents)
      _.each parents, -> it.partners.should.have.length 7
      _.each parents, -> _.uniq(it.partners).should.have.length 1
