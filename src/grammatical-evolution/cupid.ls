_ = require \underscore

class exports.Cupid
  ({@children-per-couple}) ->
    @_validate-children-per-couple()

  function isnt-whole-number(n)
    (n %% 1) isnt 0

  _validate-children-per-couple: ->
    unless @children-per-couple?
      throw new Error "Missing mandatory arg childrenPerCouple"
    else if isnt-whole-number(@children-per-couple)
      throw new Error "Invalid arg. @childrenPerCouple should be an integer"


  match: (parents) ->
    mixed = _.shuffle parents
    kids = []
    for dad, i in mixed by 2
      mum = mixed[i + 1]
      _.times @children-per-couple, -> kids.push dad.screw(mum)
    kids


