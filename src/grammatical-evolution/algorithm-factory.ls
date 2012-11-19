_ = require \underscore

class exports.AlgorithmFactory
  ({@grammar,@prefix-code='',@postfix-code=''}:opts={}) ->
    @_validate-mandatory-args()

  _validate-mandatory-args: ->
    unless @grammar?
      throw new Error "Missing mandatory arg `grammar`"

  build: (ints) ->
    state =
      integers: ints
      depth: 0
      offset: 0
      code: \S
    do
      _ @grammar.keys .each (key) ~>
        @expand-key(state, key)
      @depth++
    until @grammar.is-finished state.code
    "#{@prefix-code}\n#{state.code}\n#{@postfix-code}"

  expand-key: (state, key) ->
    state.code = state.code.replace new RegExp(key, 'g'), ~> @expansion-for-key(state, it)

  expansion-for-key: (state, key) ->
    options = @grammar.get-options-for(key, state.depth)
    index = @next-integer(state) % options.length
    options[index]

  next-integer: (state) ->
    i = state.integers[@_get-offset(state)]
    @_increment-offset(state)
    i

  _increment-offset: (state) ->
    state.offset = if (@_get-offset(state) == state.integers.length - 1) then 0 else state.offset + 1

  _get-offset: (state) ->
    state.offset ?= 0
