(function(){
  var _, GeneHelperBuilder;
  _ = require('underscore');
  exports.GeneHelperBuilder = GeneHelperBuilder = (function(){
    GeneHelperBuilder.displayName = 'GeneHelperBuilder';
    var defaults, prototype = GeneHelperBuilder.prototype, constructor = GeneHelperBuilder;
    defaults = {
      base: 2,
      codonBits: 8
    };
    function GeneHelperBuilder(config){
      config == null && (config = {});
      _.extend(this.opts = {}, defaults, config);
    }
    prototype.get = function(field){
      return this.opts[field];
    };
    prototype.build = function(){
      var ref$, codonBits, base, helperObject;
      ref$ = this.opts, codonBits = ref$.codonBits, base = ref$.base;
      helperObject = {
        bitsToInts: function(bs){
          var codons;
          codons = splitBitstring(bs);
          return _.map(codons, function(c){
            return parseInt(c, base);
          });
        },
        intsToBits: function(ints){
          var this$ = this;
          return _(ints).map(function(it){
            return pad(
            it.toString(base));
          }).join('');
        }
      };
      function splitBitstring(bitstring){
        var re;
        re = new RegExp(".{" + codonBits + "}", 'g');
        return bitstring.match(re);
      }
      function pad(s){
        return repeatString$('0', codonBits - s.length) + s;
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
