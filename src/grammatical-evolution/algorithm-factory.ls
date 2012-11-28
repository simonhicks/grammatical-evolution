_ = require \underscore

class exports.AlgorithmFactory
  ({@grammar,@prefix-code='',@postfix-code='',@wrapper-function=null}:opts={}) ->
    @_validate-mandatory-args()


  _validate-mandatory-args: ->
    unless @grammar?
      throw new Error "Missing mandatory arg `grammar`"


  build: (ints) ->
    state = @_make-state(ints)
    do
      _ @grammar.keys .each (key) ~>
        @expand-key(state, key)
      state.depth++
    until @grammar.is-finished(state.code)

    @_wrap-code(state.code)


  _wrap-code: (code) ->
    code |> @_add-function |> @_add-wrappers


  _add-function: (code) ~>
    code-with-function = if @wrapper-function?
      """function #{@wrapper-function}() {
        return #code;
      }"""
    else
      code


  _add-wrappers: (code) ~>
    "#{@prefix-code}\n#{code}\n#{@postfix-code}"


  _make-state: (ints) ->
    integers: ints
    depth: 0
    offset: 0
    code: \S


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
    state.offset = if (@_get-offset(state) == state.integers.length - 1) then 0 else @_get-offset(state) + 1


  _get-offset: (state) ->
    state.offset ?= 0
