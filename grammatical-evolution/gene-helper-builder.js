(function(){
  var _, GeneHelperBuilder, slice$ = [].slice;
  _ = require('underscore');
  exports.GeneHelperBuilder = GeneHelperBuilder = (function(){
    GeneHelperBuilder.displayName = 'GeneHelperBuilder';
    var defaults, prototype = GeneHelperBuilder.prototype, constructor = GeneHelperBuilder;
    defaults = {
      base: 2,
      codonBits: 8,
      pointMutationRate: 1,
      crossoverRate: 0.3,
      duplicationRate: 1,
      deletionRate: 0.5,
      numberOfCodons: 10
    };
    function GeneHelperBuilder(config){
      config == null && (config = {});
      _.extend(this.opts = {}, defaults, config);
    }
    prototype.get = function(field){
      return this.opts[field];
    };
    prototype.build = function(){
      var ref$, codonBits, base, pointMutationRate, crossoverRate, duplicationRate, deletionRate, numberOfCodons, helperObject;
      ref$ = this.opts, codonBits = ref$.codonBits, base = ref$.base, pointMutationRate = ref$.pointMutationRate, crossoverRate = ref$.crossoverRate, duplicationRate = ref$.duplicationRate, deletionRate = ref$.deletionRate, numberOfCodons = ref$.numberOfCodons;
      helperObject = new function(){
        var this$ = this;
        this.bitsToInts = function(bits){
          var codons;
          codons = splitBitstring(bits);
          return _.map(codons, function(c){
            return parseInt(c, base);
          });
        };
        this.intsToBits = function(ints){
          return _(ints).map(function(it){
            return pad(
            it.toString(base));
          }).join('');
        };
        this.mutatePoint = function(bits){
          var child;
          child = _.map(bits, function(bit){
            if (maybe(pointMutationRate / bits.length)) {
              return flipBit(bit);
            } else {
              return bit;
            }
          });
          return child.join('');
        };
        this.singlePointCrossover = function(p1, p2){
          var p1Ints, p2Ints, cut;
          if (maybe(crossoverRate)) {
            p1Ints = this$.bitsToInts(p1);
            p2Ints = this$.bitsToInts(p2);
            cut = randomInt(_.min([p1Ints.length, p2Ints.length]));
            return this$.intsToBits(slice$.call(p1Ints, 0, cut).concat(p2Ints.slice(cut)));
          } else {
            return p1;
          }
        };
        this.duplicateCodon = function(bits){
          var ints, i;
          if (maybe(duplicationRate / codonBits)) {
            ints = this$.bitsToInts(bits);
            i = randomInt(ints.length);
            ints.push(ints[i]);
            return this$.intsToBits(ints);
          } else {
            return bits;
          }
        };
        this.deleteCodon = function(bits){
          var ints, i, res;
          if (maybe(deletionRate / codonBits)) {
            ints = this$.bitsToInts(bits);
            i = randomInt(ints.length);
            res = slice$.call(ints, 0, i).concat(ints.slice(i + 1));
            return this$.intsToBits(res);
          } else {
            return bits;
          }
        };
        this.randomBitstring = function(){
          var i;
          return this$.intsToBits(
          (function(){
            var i$, to$, results$ = [];
            for (i$ = 0, to$ = numberOfCodons; i$ < to$; ++i$) {
              i = i$;
              results$.push(randomInt(base));
            }
            return results$;
          }()));
        };
        this.reproduce = function(p1, p2){
          return this$.pointMutation(
          this$.deleteCodon(
          this$.duplicateCodon(
          this$.singlePointCrossover(p1, p2))));
        };
        return this;
      };
      function splitBitstring(bitstring){
        var re;
        re = new RegExp(".{" + codonBits + "}", 'g');
        return bitstring.match(re);
      }
      function pad(s){
        return repeatString$('0', codonBits - s.length) + s;
      }
      function flipBit(bit){
        var options, res$, i$, to$, b;
        if (base === 2) {
          return 1 ^ parseInt(bit, base);
        } else {
          res$ = [];
          for (i$ = 0, to$ = base; i$ < to$; ++i$) {
            b = i$;
            if (b + "" !== bit + "") {
              res$.push(b);
            }
          }
          options = res$;
          return options[randomInt(options.length)];
        }
      }
      function maybe(p){
        return Math.random() < p;
      }
      function randomInt(limit){
        return Math.floor(Math.random() * limit);
      }
      return helperObject;
    };
    return GeneHelperBuilder;
  }());
  function repeatString$(str, n){
    for (var r = ''; n > 0; (n >>= 1) && (str += str)) if (n & 1) r += str;
    return r;
  }
}).call(this);
