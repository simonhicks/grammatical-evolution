(function(){
  var _, GeneticHelper, vm, CodeBuilder, Tournament, slice$ = [].slice;
  _ = require('underscore');
  function random(limit){
    return Math.floor(Math.random() * limit);
  }
  GeneticHelper = (function(){
    GeneticHelper.displayName = 'GeneticHelper';
    var BASE, prototype = GeneticHelper.prototype, constructor = GeneticHelper;
    BASE = 2;
    function GeneticHelper(opts){
      var ref$, ref1$;
      ref$ = opts != null
        ? opts
        : {}, this.codonBits = (ref1$ = ref$.codonBits) != null ? ref1$ : 8, this.pCross = (ref1$ = ref$.pCross) != null ? ref1$ : 0.3;
      this.onePointCrossover = bind$(this, 'onePointCrossover', prototype);
      this.pointMutation = bind$(this, 'pointMutation', prototype);
      this.flipBit = bind$(this, 'flipBit', prototype);
      this.bitsToInts = bind$(this, 'bitsToInts', prototype);
      this.intsToBits = bind$(this, 'intsToBits', prototype);
    }
    prototype.intsToBits = function(ints){
      var ljust, binaryStrings, this$ = this;
      ljust = function(s){
        return repeatString$('0', this$.codonBits - s.length) + s;
      };
      binaryStrings = _.map(ints, function(it){
        return ljust(it.toString(BASE));
      });
      return binaryStrings.join('');
    };
    prototype.bitsToInts = function(bits){
      var bitArray, ints, section, this$ = this;
      bitArray = bits.split('');
      ints = [];
      while (bitArray.length > 0) {
        section = [];
        _.times(this.codonBits, fn$);
        ints.push(
        partialize$(parseInt, [void 8, BASE], [0])(
        fn1$(
        section)));
      }
      return ints;
      function fn$(){
        return section.push(bitArray.shift());
      }
      function fn1$(it){
        return it.join('');
      }
    };
    prototype.flipBit = function(bit){
      return 1 ^ parseInt(bit, BASE);
    };
    prototype.pointMutation = function(bits){
      var child, this$ = this;
      child = _.map(bits, function(bit){
        if (Math.random() < 1.0 / bits.length) {
          return this$.flipBit(bit);
        } else {
          return bit;
        }
      });
      return child.join('');
    };
    prototype.onePointCrossover = function(parent1, parent2){
      var p1Ints, p2Ints, cut;
      if (Math.random() < this.pCross) {
        p1Ints = this.bitsToInts(parent1);
        p2Ints = this.bitsToInts(parent2);
        cut = random(_.min([p1Ints.length, p2Ints.length]));
        return this.intsToBits(slice$.call(p1Ints, 0, cut).concat(p2Ints.slice(cut)));
      } else {
        return _.clone(parent1);
      }
    };
    prototype.codonDuplication = function(bits){
      var ints, i;
      if (Math.random() < 0.5 / this.codonBits) {
        ints = this.bitsToInts(bits);
        i = random(ints.length);
        ints.push(ints[i]);
        return this.intsToBits(ints);
      } else {
        return _.clone(bits);
      }
    };
    return GeneticHelper;
  }());
  vm = require('vm');
  function gsub(str, target, func){
    var words, res, i$, len$, word;
    words = _.compact(str.split(/\s+/));
    res = '';
    for (i$ = 0, len$ = words.length; i$ < len$; ++i$) {
      word = words[i$];
      if (word === target) {
        res = res + " " + func(word);
      } else {
        res += " " + word;
      }
    }
    return res;
  }
  CodeBuilder = (function(){
    CodeBuilder.displayName = 'CodeBuilder';
    var prototype = CodeBuilder.prototype, constructor = CodeBuilder;
    CodeBuilder.minDepth = 2;
    CodeBuilder.maxDepth = 7;
    CodeBuilder.grammar = {
      S: 'EXP',
      EXP: [' FUNC ( EXP , EXP ) ', 'VAR'],
      FUNC: ['add', 'sub', 'div', 'mul'],
      VAR: ['x', '1.0']
    };
    CodeBuilder.functionDefinitions = 'function add(a, b) {\n  return a + b;\n}\n\nfunction sub(a, b) {\n  return a - b;\n}\n\nfunction div(a, b) {\n  if (b === 0) {\n    return a;\n  } else {\n    return a / b;\n  }\n}\n\nfunction mul(a, b) {\n  return a * b;\n}';
    function CodeBuilder(integers){
      var ref$, done, offset, depth, symbolicString, this$ = this;
      ref$ = [false, 0, 0], done = ref$[0], offset = ref$[1], depth = ref$[2];
      symbolicString = constructor.grammar['S'];
      do {
        done = true;
        _.chain(constructor.grammar).keys().each(fn$);
        depth++;
      } while (!done);
      this.code = constructor.functionDefinitions + "\n\n" + symbolicString;
      function fn$(key){
        return symbolicString = gsub(symbolicString, key, function(k){
          var set, next, integer;
          done = false;
          set = k === 'EXP' && depth >= constructor.maxDepth - 1
            ? constructor.grammar['VAR']
            : constructor.grammar[k];
          do {
            integer = integers[offset] % set.length;
            offset = offset === integers.length - 1
              ? 0
              : offset + 1;
            next = set[integer];
          } while (!(depth > constructor.minDepth || next !== 'VAR'));
          return next;
        });
      }
    }
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
  function repeatString$(str, n){
    for (var r = ''; n > 0; (n >>= 1) && (str += str)) if (n & 1) r += str;
    return r;
  }
  function partialize$(f, args, where){
    return function(){
      var params = slice$.call(arguments), i,
          len = params.length, wlen = where.length,
          ta = args ? args.concat() : [], tw = where ? where.concat() : [];
      for(i = 0; i < len; ++i) { ta[tw[0]] = params[i]; tw.shift(); }
      return len < wlen && len ? partialize$(f, ta, tw) : f.apply(this, ta);
    };
  }
}).call(this);
