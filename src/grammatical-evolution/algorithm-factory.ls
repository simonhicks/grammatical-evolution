
class exports.AlgorithmFactory
  ({@grammar,@prefix-code='',@postfix-code=''}:opts={}) ->
    @_validate-mandatory-args()

  _validate-mandatory-args: ->
    unless @grammar?
      throw new Error "Missing mandatory arg `grammar`"

  create: (integers)
