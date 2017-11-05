package reselect;

import haxe.extern.EitherType;
import haxe.Constraints.Function;

typedef StateSelector<TState, T> = TState -> T;
typedef StateAndMaybePropsSelector<TState, TProps, T> = TState -> ?TProps -> T;
typedef StateAndPropsSelector<TState, TProps, T> = EitherType<TState -> TProps -> T, StateAndMaybePropsSelector<TState, TProps, T>>;
typedef Selector<TState, TProps, T> = EitherType<StateSelector<TState, T>, StateAndPropsSelector<TState, TProps, T>>;

@:jsRequire('reselect')
@:build(reselect.ReselectMacro.buildCreateSelector())
extern class Reselect {
	public static function createSelector(selectors:Array<Function>, resultFunc:Function):Function;
}
