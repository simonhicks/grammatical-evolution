(function(){
  var should, _, GeneHelperBuilder;
  should = require('should');
  _ = require('underscore');
  GeneHelperBuilder = require('../../grammatical-evolution/gene-helper-builder').GeneHelperBuilder;
  suite('GeneHelperBuilder', function(){
    suite('when being configured', function(){
      var testArgument;
      testArgument = function(fieldName, dflt){
        test(fieldName + " should default to " + dflt, function(){
          var builder;
          builder = new GeneHelperBuilder();
          return builder.get(fieldName).should.equal(dflt);
        });
        return test(fieldName + " should be configurable", function(){
          var opts, builder;
          opts = {};
          opts[fieldName] = Math.random();
          builder = new GeneHelperBuilder(opts);
          return builder.get(fieldName).should.equal(opts[fieldName]);
        });
      };
      testArgument('base', 2);
      return testArgument('codonBits', 8);
    });
    return suite('when using a binary helper object', function(){
      var ints, bits;
      ints = [0, 1, 2, 3, 4, 5, 6, 7];
      bits = '00000001001000110100010101100111';
      setup(function(){
        this.opts = {
          base: 2,
          codonBits: 4
        };
        return this.createHelper = function(){
          return new GeneHelperBuilder(this.opts).build();
        };
      });
      test('should build a helper object', function(){
        return this.createHelper().should.be.an.instanceOf(Object);
      });
      test('the helper should convert bits to ints', function(){
        var helper;
        helper = this.createHelper();
        return helper.bitsToInts(bits).should.eql(ints);
      });
      test('the helper should convert ints to bits', function(){
        var helper;
        helper = this.createHelper();
        return helper.intsToBits(ints).should.eql(bits);
      });
      return test("changing the @opts in the builder, shouldn't affect the helper once it's created");
    });
  });
}).call(this);
