package reselect;

import haxe.Constraints.Function;
import reselect.Reselect.Selector;

class ReselectHelper {
	public static function recomputations<TState, TProps, T>(selector:Selector<TState, TProps, T>):Int {
		return untyped selector.recomputations();
	}

	public static function resetRecomputations<TState, TProps, T>(selector:Selector<TState, TProps, T>):Void {
		return untyped selector.resetRecomputations();
	}

	public static function getResultFunc<TState, TProps, T>(selector:Selector<TState, TProps, T>):Function {
		return untyped selector.resultFunc;
	}
}
