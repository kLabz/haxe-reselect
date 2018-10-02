package reselect;

import haxe.extern.EitherType;
import haxe.extern.Rest;
import haxe.Constraints.Function;

typedef StateSelector<TState, T> = TState -> T;
typedef StateAndMaybePropsSelector<TState, TProps, T> = TState -> ?TProps -> T;
typedef StateAndPropsSelector<TState, TProps, T> = EitherType<TState -> TProps -> T, StateAndMaybePropsSelector<TState, TProps, T>>;
typedef Selector<TState, TProps, T> = EitherType<StateSelector<TState, T>, StateAndPropsSelector<TState, TProps, T>>;

#if reselect_global 
@:native('Reselect')
#else
@:jsRequire('reselect')
#end
@:build(reselect.ReselectMacro.buildCreateSelector())
extern class Reselect {
	public static function createSelector(selectors:Array<Function>, resultFunc:Function):Function;

	// TODO: somehow return a function with the same signature as createSelector(...)
	public static function createSelectorCreator(memoize:Function, options:Rest<Dynamic>):Function;
	public static function createStructuredSelector(inputSelectors:Dynamic<Function>, selectorCreator:Function = createSelector):Function;

	// TODO: better typing
	public static function defaultMemoize<TFunc: Function, TValue>(func:TFunc, equalityCheck:TValue->TValue->Bool = defaultEqualityCheck):TFunc;
	public static function defaultEqualityCheck<TValue>(currentValue:TValue, previousValue:TValue):Bool;
}
