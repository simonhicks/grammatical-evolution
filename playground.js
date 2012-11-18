(function(){
  var _, Grammar, vm, CodeBuilder, Tournament;
  _ = require('underscore');
  Grammar = require('./grammatical-evolution/grammar').Grammar;
  vm = require('vm');
  CodeBuilder = (function(){
    CodeBuilder.displayName = 'CodeBuilder';
    var prototype = CodeBuilder.prototype, constructor = CodeBuilder;
    CodeBuilder.minDepth = 2;
    CodeBuilder.maxDepth = 7;
    CodeBuilder.grammar = {
      S: 'EXP',
      EXP: ['FUNC(EXP, EXP)', 'VAR'],
      FUNC: ['add', 'sub', 'div', 'mul'],
      VAR: ['x', '1.0']
    };
    CodeBuilder.terminalKeys = ['VAR'];
    CodeBuilder.expandableKeys = ['EXP'];
    CodeBuilder.functionDefinitions = 'function add(a, b) {\n  return a + b;\n}\n\nfunction sub(a, b) {\n  return a - b;\n}\n\nfunction div(a, b) {\n  if (b === 0) {\n    return a;\n  } else {\n    return a / b;\n  }\n}\n\nfunction mul(a, b) {\n  return a * b;\n}';
    function CodeBuilder(integers){
      var ref$;
      this.integers = integers;
      this.filterForDepth = bind$(this, 'filterForDepth', prototype);
      this.isExpandable = bind$(this, 'isExpandable', prototype);
      this.isTerminal = bind$(this, 'isTerminal', prototype);
      this.expansionForKey = bind$(this, 'expansionForKey', prototype);
      ref$ = [0, 0], this.offset = ref$[0], this.depth = ref$[1];
      this.symbolicString = constructor.grammar['S'];
      do {
        this.expandKeys();
      } while (this['continue']());
      this.code = constructor.functionDefinitions + "\n\n" + this.symbolicString + ";";
    }
    prototype.expandKeys = function(){
      var this$ = this;
      _.chain(constructor.grammar).keys().each(function(key){
        return this$.expandKey(key);
      });
      return this.depth++;
    };
    prototype.expandKey = function(key){
      return this.symbolicString = this.symbolicString.replace(new RegExp(key, 'g'), this.expansionForKey);
    };
    prototype.expansionForKey = function(key){
      var set, index;
      set = this.optionsForKey(key);
      index = this.nextInteger() % set.length;
      this.incrementOffset();
      return set[index];
    };
    prototype.isTerminal = function(key){
      return _.any(constructor.terminalKeys, function(it){
        return key === it;
      });
    };
    prototype.isExpandable = function(str){
      return _.any(constructor.expandableKeys, function(it){
        return str.match(it);
      });
    };
    prototype.optionsForKey = function(key){
      return this.filterForDepth(
      constructor.grammar[key]);
    };
    prototype.filterForDepth = function(options){
      switch (false) {
      case !(this.depth < constructor.minDepth):
        return _.reject(options, this.isTerminal);
      case !(this.depth > constructor.maxDepth - 1):
        return _.reject(options, this.isExpandable);
      default:
        return options;
      }
    };
    prototype.nextInteger = function(){
      return this.integers[this.offset];
    };
    prototype.incrementOffset = function(){
      return this.offset = this.offset === this.integers.length - 1
        ? 0
        : this.offset + 1;
    };
    prototype['continue'] = function(){
      var patterns, this$ = this;
      patterns = _.chain(constructor.grammar).keys().map(function(it){
        return new RegExp(it);
      }).value();
      return _.any(patterns, function(it){
        return it.test(this$.symbolicString);
      });
    };
    return CodeBuilder;
  }());
  Tournament = (function(){
    Tournament.displayName = 'Tournament';
    var prototype = Tournament.prototype, constructor = Tournament;
    Tournament.DEFAULT_ROUNDS = 10;
    Tournament.run = function(opts){
      var instance, res;
      instance = new this(opts);
      instance.play();
      res = _.sortBy(instance.getBots(), function(arg$){
        var id;
        id = arg$.id;
        return instance.getWins(id);
      }).reverse();
      return instance.getResults();
    };
    function Tournament(arg$){
      this.bots = arg$.bots, this.rounds = arg$.rounds, this.gameOptions = arg$.gameOptions;
      this._playRound = bind$(this, '_playRound', prototype);
      this._awardPoint = bind$(this, '_awardPoint', prototype);
      this._playMatch = bind$(this, '_playMatch', prototype);
      this._points = {};
      this._validateBots();
      this._validateRounds();
    }
    prototype._validateBots = function(){
      if (this.bots == null) {
        return this._missingArg('bots');
      } else if (this.bots.length < 2) {
        return this._invalidArg('bots', 'must contain at least 2 bots');
      } else if (!_.all(this.bots, function(it){
        return it.constructor === Bot;
      })) {
        return this._invalidArg('bots', 'should only contain instances of Bot');
      }
    };
    prototype._validateRounds = function(){
      var ref$;
      return (ref$ = this.rounds) != null
        ? ref$
        : this.rounds = constructor.DEFAULT_ROUNDS;
    };
    prototype.getBots = function(){
      return this.bots;
    };
    prototype.getWins = function(id){
      var ref$;
      return (ref$ = this._points[id]) != null ? ref$ : 0;
    };
    prototype._missingArg = function(field){
      throw new Error("Missing mandatory arg " + field);
    };
    prototype._invalidArg = function(field, msg){
      throw new Error("Invalid arg " + field + ". " + field + " " + msg + ".");
    };
    prototype._playMatch = function(bot1, bot2){
      return this._awardPoint(
      Game.play(bot1, bot2, this.gameOptions));
    };
    prototype._awardPoint = function(winner){
      var ref$;
      (ref$ = this._points)[winner] == null && (ref$[winner] = 0);
      return this._points[winner]++;
    };
    prototype._playRound = function(){
      var i$, ref$, len$, i1, bot1, j$, ref1$, len1$, i2, bot2, results$ = [];
      for (i$ = 0, len$ = (ref$ = this.bots).length; i$ < len$; ++i$) {
        i1 = i$;
        bot1 = ref$[i$];
        for (j$ = 0, len1$ = (ref1$ = this.bots).length; j$ < len1$; ++j$) {
          i2 = j$;
          bot2 = ref1$[j$];
          if (i1 < i2) {
            results$.push(this._playMatch(bot1, bot2));
          }
        }
      }
      return results$;
    };
    prototype.play = function(){
      return _.times(this.rounds, this._playRound);
    };
    prototype.getResults = function(){
      var this$ = this;
      return _.sortBy(this.getBots(), function(arg$){
        var id;
        id = arg$.id;
        return this$.getWins(id);
      }).reverse();
    };
    return Tournament;
  }());
  function bind$(obj, key, target){
    return function(){ return (target || obj)[key].apply(obj, arguments) };
  }
}).call(this);
