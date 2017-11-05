package test;

import haxe.Timer;
import buddy.SingleSuite;
import reselect.Reselect.createSelector;

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
	}

	public static function shallowCompare(a:Dynamic, b:Dynamic):Bool {
		var aFields = Reflect.fields(a);
		var bFields = Reflect.fields(b);

		if (aFields.length != bFields.length) return false;
		if (aFields.length == 0) return a == b;

		for (field in aFields)
			if (!Reflect.hasField(b, field) || Reflect.field(b, field) != Reflect.field(a, field))
				return false;

		return true;
	}
}
