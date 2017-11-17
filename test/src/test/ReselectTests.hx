package test;

import haxe.Constraints.Function;
import haxe.Serializer;
import haxe.Timer;
import buddy.SingleSuite;
import reselect.Reselect.createSelector;
import reselect.Reselect.createSelectorCreator;
import reselect.Reselect.createStructuredSelector;
import reselect.Reselect.defaultMemoize;

using buddy.Should;
using reselect.ReselectHelper;

typedef TestState1 = {
	?a: Int,
	?b: Int,
	?value: Int
}

typedef TestState2 = {
	sub: TestState1,
	?x: Int
}

typedef TestProps = {
	?c: Int,
	?x: Int,
	?y: Int
}

class ReselectTests extends SingleSuite {
	public function new() {
		var numOfStates = 1000000;
		var states = [for (i in 0...numOfStates) {a: 1, b: 2}];

		// Adapted from reselect lib:
		// https://github.com/reactjs/reselect/blob/master/test/test_selector.js
		describe("Reselect.createSelector", {
			it("should handle basic selectors", {
				var selector = createSelector(
					function(state) return state.a,
					function(a) return a
				);

				var firstState = {a: 1};
				var firstStateNewPointer = {a: 1};
				var secondState = {a: 2};

				selector(firstState).should.be(1);
				selector(firstState).should.be(1);
				selector.recomputations().should.be(1);
				selector(firstStateNewPointer).should.be(1);
				selector.recomputations().should.be(1);
				selector(secondState).should.be(2);
				selector.recomputations().should.be(2);
			});

			it("should handle basic selector with multiple keys", {
				var selector = createSelector(
					function(state:TestState1) return state.a,
					function(state:TestState1) return state.b,
					function(a:Int, b:Int) return a + b
				);

				var state1 = {a: 1, b: 2};
				selector(state1).should.be(3);
				selector(state1).should.be(3);
				selector.recomputations().should.be(1);

				var state2 = {a: 3, b: 2};
				selector(state2).should.be(5);
				selector(state2).should.be(5);
				selector.recomputations().should.be(2);
			});

			#if !COVERAGE
			it("should handle a million call with the same argument in under 1sec", {
				var selector = createSelector(
					function(state:TestState1) return state.a,
					function(state:TestState1) return state.b,
					function(a:Int, b:Int) return a + b
				);

				var state1 = {a: 1, b: 2};

				var start = Timer.stamp();
				for (i in 0...1000000) selector(state1);
				var totalTime = Timer.stamp() - start;

				selector(state1).should.be(3);
				selector.recomputations().should.be(1);
				totalTime.should.beLessThan(1);
			});

			it("should handle a million call with shallowly equal arguments in under 1sec", {
				var selector = createSelector(
					function(state:TestState1) return state.a,
					function(state:TestState1) return state.b,
					function(a:Int, b:Int) return a + b
				);

				var start = Timer.stamp();
				for (i in 0...numOfStates) selector(states[i]);
				var totalTime = Timer.stamp() - start;

				selector(states[0]).should.be(3);
				selector.recomputations().should.be(1);
				totalTime.should.beLessThan(1);
			});
			#end

			it("should memoize composite arguments", {
				var selector = createSelector(
					function(state:TestState2) return state.sub,
					function(sub:TestState1) return sub
				);

				var state1 = {sub: {a: 1}};
				shallowCompare(selector(state1), {a: 1}).should.be(true);
				shallowCompare(selector(state1), {a: 1}).should.be(true);
				selector.recomputations().should.be(1);

				var state2 = {sub: {a: 2}};
				shallowCompare(selector(state2), {a: 2}).should.be(true);
				selector.recomputations().should.be(2);
			});

			it("should accept first argument as an array (needs improvement)", {
				// No strict typing with first argument as an array (for now)
				var selector = createSelector(
					[
						function(state) return state.a,
						function(state) return state.b
					],
					function(a, b) return a + b
				);

				selector({a: 1, b: 2}).should.be(3);
				selector({a: 1, b: 2}).should.be(3);

				// Typing is not accurate enough to be able to use ReselectHelper
				ReselectHelper.recomputations(cast selector).should.be(1);

				selector({a: 3, b: 2}).should.be(5);
				ReselectHelper.recomputations(cast selector).should.be(2);
			});

			it("should accept props", {
				var selector:TestState1->TestProps->Int = createSelector(
					function(state:TestState1, props:TestProps) return state.a,
					function(state:TestState1, props:TestProps) return state.b,
					function(state:TestState1, props:TestProps) return props.c,
					function(a, b, c) return a + b + c
				);

				selector({a: 1, b: 2}, {c: 100}).should.be(103);
			});

			it("should recompute result after exception", {
				var called = 0;
				var selector = createSelector(
					function(state) return state.a,
					function(_) {
						called++;
						throw "test error";
					}
				);

				selector.bind({a: 1}).should.throwValue("test error");
				selector.bind({a: 1}).should.throwValue("test error");
				called.should.be(2);
			});

			it("should memoize previous result before exception", {
				var called = 0;
				var selector = createSelector(
					function(state) return state.a,
					function(a) {
						called++;
						if (a > 1) throw "test error";
						return a;
					}
				);

				var state1 = {a: 1};
				var state2 = {a: 2};

				selector(state1).should.be(1);
				selector.bind(state2).should.throwValue("test error");
				selector(state1).should.be(1);
				called.should.be(2);
			});

			it("should chain selectors", {
				var selector1 = createSelector(
					function(state) return state.sub,
					function(sub) return sub
				);

				var selector2 = createSelector(
					selector1,
					function(sub) return sub.value
				);

				var state1 = {sub: {value: 1}};
				selector2(state1).should.be(1);
				selector2(state1).should.be(1);
				selector2.recomputations().should.be(1);

				var state2 = {sub: {value: 2}};
				selector2(state2).should.be(2);
				selector2.recomputations().should.be(2);
			});

			it("should chain selectors with props", {
				var selector1 = createSelector(
					function(state:TestState2) return state.sub,
					function(state:TestState2, props:TestProps) return props.x,
					function(sub:TestState1, x:Int) return ({sub: sub, x: x})
				);

				var selector2 = createSelector(
					selector1,
					function(state:TestState2, props:TestProps) return props.y,
					function(param:TestState2, y:Int) return param.sub.value + param.x + y
				);

				var state1 = {sub: {value: 1}};
				selector2(state1, {x: 100, y: 200}).should.be(301);
				selector2(state1, {x: 100, y: 200}).should.be(301);
				selector2.recomputations().should.be(1);

				var state2 = {sub: {value: 2}};
				selector2(state2, {x: 100, y: 201}).should.be(303);
				selector2.recomputations().should.be(2);
			});

			xit("should chain selectors with variadic args", {
				// NOT IMPLEMENTED
				"TODO".should.be("done");

				// var selector1 = createSelector(
				// 	function(state:TestState2) return state.sub,
				// 	function(state:TestState2, props:TestProps, another:Int) return props.x + another,
				// 	function(sub:TestState1, x:Int) return ({sub: sub, x: x})
				// );

				// var selector2 = createSelector(
				// 	selector1,
				// 	function(state:TestState2, props:TestProps) return props.y,
				// 	function(param:TestState2, y:Int) return param.sub.value + param.x + y
				// );

				// var state1 = {sub: {value: 1}};
				// selector2(state1, {x: 100, y: 200}, 100).should.be(401);
				// selector2(state1, {x: 100, y: 200}, 100).should.be(401);
				// selector2.recomputations().should.be(1);

				// var state2 = {sub: {value: 2}};
				// selector2(state2, {x: 100, y: 201}, 200).should.be(503);
				// selector2.recomputations().should.be(2);
			});

			it("should expose resetRecomputations()", {
				var selector = createSelector(
					function(state) return state.a,
					function(a) return a
				);

				selector({a: 1}).should.be(1);
				selector({a: 1}).should.be(1);
				selector.recomputations().should.be(1);
				selector({a: 2}).should.be(2);
				selector.recomputations().should.be(2);

				selector.resetRecomputations();
				selector.recomputations().should.be(0);

				selector({a: 1}).should.be(1);
				selector({a: 1}).should.be(1);
				selector.recomputations().should.be(1);
				selector({a: 2}).should.be(2);
				selector.recomputations().should.be(2);
			});

			it("should expose last function with getResultFunc()", {
				var lastFunction = function(_) {};
				var selector = createSelector(
					function(state) return state.a,
					lastFunction
				);

				selector.getResultFunc().should.be(lastFunction);
			});
		});

		describe("Reselect.defaultMemoize", {
			it("should memoize functions", {
				var called = 0;
				var memoized = defaultMemoize(function(state) {
					called++;
					return state.a;
				});

				var o1 = {a: 1};
				var o2 = {a: 2};

				memoized(o1).should.be(1);
				memoized(o1).should.be(1);
				called.should.be(1);
				memoized(o2).should.be(2);
				called.should.be(2);
			});

			it("should memoize functions with multiple arguments", {
				var memoized:Function = defaultMemoize(
					Reflect.makeVarArgs(function(args:Array<Dynamic>) {
						return Lambda.fold(args, function(sum, value) return sum + value, 0);
					})
				);

				memoized(1, 2).should.be(3);
				memoized(1).should.be(1);
			});

			it("should allow valueEquals override", {
				var called = 0;
				var memoized = defaultMemoize(
					function(a) {
						called++;
						return a;
					},
					// a rather absurd equals operation we can verify in tests
					function(a, b) return Math.abs(a - b) < 10
				);

				memoized(1).should.be(1);
				memoized(2).should.be(1);
				called.should.be(1);
				memoized(42).should.be(42);
				called.should.be(2);
			});

			it("should pass correct objects to equalityCheck", {
				var fallthroughs = 0;
				var shallowEqual = function(newVal, oldVal) {
					if (newVal == oldVal) return true;
					fallthroughs++;
					return shallowCompare(newVal, oldVal);
				};

				var someObject = {foo: "bar"};
				var anotherObject = {foo: "bar"};
				var memoized = defaultMemoize(function(a) return a, shallowEqual);

				// the first call to `memoized` doesn't hit because `defaultMemoize.lastArgs` is uninitialized
				// and so `equalityCheck` is never called
				memoized(someObject);
				fallthroughs.should.be(0);

				// the next call, with a different object reference, does fall through
				memoized(anotherObject);
				fallthroughs.should.be(1);

				// the third call does not fall through because `defaultMemoize` passes `anotherObject` as
				// both the `newVal` and `oldVal` params. This allows `shallowEqual` to be much more performant
				// than if it had passed `someObject` as `oldVal`, even though `someObject` and `anotherObject`
				// are shallowly equal
				memoized(anotherObject);
				fallthroughs.should.be(1);
			});
		});

		describe("Reselect.createSelectorCreator", {
			it("should allow valueEquals overriding", {
				var createOverridenSelector = createSelectorCreator(
					defaultMemoize,
					// a rather absurd equals operation we can verify in tests
					function(a, b) return Math.abs(a - b) < 10
				);

				var selector:TestState1->Int = createOverridenSelector(
					function(state) return state.a,
					function(a) return a
				);

				selector({a: 1}).should.be(1);
				selector({a: 2}).should.be(1);
				selector.recomputations().should.be(1);

				selector({a: 42}).should.be(42);
				selector.recomputations().should.be(2);
			});

			it("should allow custom memoize functions", {
				var hashMemoizeCalls = 0;
				var customSelectorCreator = createSelectorCreator(
					hashMemoize,
					Serializer.run,
					function() {
						hashMemoizeCalls++;
					}
				);

				var selector:TestState1->Int = customSelectorCreator(
					function(state) return state.a,
					function(state) return state.b,
					function(a, b) return a + b
				);

				selector({a: 1, b: 2}).should.be(3);
				selector({a: 1, b: 2}).should.be(3);
				selector.recomputations().should.be(1);
				hashMemoizeCalls.should.be(2);

				selector({a: 1, b: 3}).should.be(4);
				selector.recomputations().should.be(2);
				hashMemoizeCalls.should.be(3);

				selector({a: 1, b: 3}).should.be(4);
				selector.recomputations().should.be(2);
				hashMemoizeCalls.should.be(4);

				selector({a: 2, b: 3}).should.be(5);
				selector.recomputations().should.be(3);
				hashMemoizeCalls.should.be(5);
			});
		});

		describe("Reselect.createStructuredSelector", {
			it("should handle basic selectors", {
				var selector = createStructuredSelector({
					x: function(state) return state.a,
					y: function(state) return state.b
				});

				var firstResult = selector({a: 1, b: 2});
				shallowCompare(firstResult, {x: 1, y: 2}).should.be(true);
				selector({a: 1, b: 2}).should.be(firstResult);

				var secondResult = selector({a: 2, b: 2});
				shallowCompare(secondResult, {x: 2, y: 2}).should.be(true);
				selector({a: 2, b: 2}).should.be(secondResult);
			});

			it("should work with custom selector creator", {
				var customSelectorCreator = createSelectorCreator(
					defaultMemoize,
					function(a, b) return a == b
				);

				var selector = createStructuredSelector({
					x: function(state) return state.a,
					y: function(state) return state.b
				}, customSelectorCreator);

				var firstResult = selector({a: 1, b: 2});
				shallowCompare(firstResult, {x: 1, y: 2}).should.be(true);
				selector({a: 1, b: 2}).should.be(firstResult);
				shallowCompare(selector({a: 2, b: 2}), {x: 2, y: 2}).should.be(true);
			});
		});
	}

	static function shallowCompare(a:Dynamic, b:Dynamic):Bool {
		var aFields = Reflect.fields(a);
		var bFields = Reflect.fields(b);

		if (aFields.length != bFields.length) return false;
		if (aFields.length == 0) return a == b;

		for (field in aFields)
			if (!Reflect.hasField(b, field) || Reflect.field(b, field) != Reflect.field(a, field))
				return false;

		return true;
	}

	static function hashMemoize(fun:Function, generateHash:Dynamic->String, logger:Void->Void):Function {
		var cache = new Map<String, Dynamic>();

		return Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			var hash = generateHash(args);
			logger();

			if (cache.exists(hash)) {
				return cache.get(hash);
			}

			var ret = Reflect.callMethod(null, fun, args);
			cache.set(hash, ret);
			return ret;
		});
	}
}
