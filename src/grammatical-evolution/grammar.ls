_ = require \underscore

class exports.Grammar
  (@rules) ->
    @keys = _.keys @rules
    @key-regexp = new RegExp @keys.join("|"), 'g'
    @validate()

  validate: ->
    for key in @keys when @_expands-to-self(key)
      throw new Error "Invalid Grammar: #key expands to itself causing a recursive loop"
    unless @rules[\S]?
      throw new Error "Invalid Grammar: missing mandatory starting key 'S'"
    unless @_is-expandable-key(\S)
      throw new Error "Invalid Grammar: starting key S is not expandable"

  _expands-to-self: (key) ~>
    @_expands-to key, key

  _expands-to: (target, src, checked=[]) ~>
    _.any @rules[src], ~>
      | it == target => true
      | _.contains(checked, it) => false
      | otherwise =>
        checked.push(it)
        @_expands-to(target, it, checked)

  initial-options: ->
    @rules[\S]

  is-expandable: (key) ~>
    @_is-expandable-key(key)

  _is-expandable-key: (key) ~>
    @_is-expandable-key-cache ?= {}
    @_is-expandable-key-cache[key] ?= _.any @rules[key], ~> @_is-expandable-expr(it)

  _is-expandable-expr: (expr) ~>
    if matched-keys = expr.match(@key-regexp)
      if matched-keys.length > 1
        true
      else
        @_is-expandable-key(matched-keys[0])

  is-terminal: (key) ~>
    @_is-terminal-key(key)

  _is-terminal-key: (key) ~>
    @_is-terminal-key-cache ?= {}
    @_is-terminal-key-cache[key] ?= @_expands-to(key, \S) and not @_is-expandable-key(key)
