_ = require \underscore

class exports.Grammar
  @MAX-DEPTH = 7
  @MIN-DEPTH = 2

  ({@rules, @max-depth=@@MAX-DEPTH, @min-depth=@@MIN-DEPTH}) ->
    @validate-args()
    @keys = _.keys @rules
    @key-regexp = new RegExp @keys.join("|"), 'g'
    @validate-rules()

  validate-args: ->
    unless @rules?
      throw new Error "Missing mandatory arg `rules`"

  validate-rules: ->
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

  is-expandable: (str) ~>
    if _.contains @keys, str
      @_is-expandable-key(str)
    else
      @_is-expandable-expr(str)

  _is-expandable-key: (key) ~>
    @_is-expandable-key-cache ?= {}
    @_is-expandable-key-cache[key] ?= _.any @rules[key], ~> @_is-expandable-expr(it)

  _is-expandable-expr: (expr) ~>
    if matched-keys = expr.match(@key-regexp)
      if matched-keys.length > 1
        true
      else
        @_is-expandable-key(matched-keys[0])

  get-options-for: (key, depth) ~>
    | depth < @min-depth => @_filter-if-possible @rules[key], ~> not @is-expandable(it)
    | depth > (@max-depth - 1) => @_filter-if-possible @rules[key], @is-expandable
    | otherwise => @rules[key]

  _filter-if-possible: (exprs, pred) ~>
    filtered = _.reject exprs, pred
    if filtered.length is 0 then exprs else filtered
