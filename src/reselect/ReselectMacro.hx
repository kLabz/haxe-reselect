package reselect;

import haxe.macro.Expr;
import haxe.macro.Context;

enum SelectorKind {
	State;
	StateAndProps;
}

class ReselectMacro {
	static inline var MAX_ARGS:Int = 26;
	static inline var DEFAULT_MAX_ARGS:Int = 5;
	static inline var MAX_ARGS_META = "reselect-max-args";
	static inline var ARGS_TYPE_NAMES = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

	public static function buildCreateSelector():Array<Field> {
		var fields:Array<Field> = Context.getBuildFields();

		var createSelector = Lambda.find(fields, function(f) return f.name == 'createSelector');
		if (createSelector != null) {
			var maxArgs = DEFAULT_MAX_ARGS;
			var definedMaxArgs = Context.defined(MAX_ARGS_META)
				? Std.parseInt(Context.definedValue(MAX_ARGS_META))
				: null;

			if (definedMaxArgs != null && definedMaxArgs < MAX_ARGS && definedMaxArgs > 0)
				maxArgs = definedMaxArgs;

			for (i in 0...maxArgs) {
				addCreateSelectorSignature(createSelector, i, StateAndProps);
				addCreateSelectorSignature(createSelector, i, State);
			}
		}

		return fields;
	}

	static function addCreateSelectorSignature(createSelector:Field, nArgs:Int, selectorKind:SelectorKind) {
		var sig = generateCreateSelectorSignature(nArgs, selectorKind, createSelector.pos);

		createSelector.meta.push({
			name: ':overload',
			params: [{expr: sig, pos: createSelector.pos}],
			pos: createSelector.pos
		});
	}

	static function generateCreateSelectorSignature(nArgs:Int, selectorKind:SelectorKind, pos:Position):ExprDef {
		var args = [];
		var params = [];
		params.push(makeParam("TState"));
		params.push(makeParam("TProps"));

		for (i in 0...nArgs) {
			args.push(makeArg(i));
			params.push(makeParam(ARGS_TYPE_NAMES.charAt(i)));
		}

		args.push(makeResultFunc(nArgs));
		params.push(makeParam("Ret"));

		var ret = switch(selectorKind) {
			case State:
				TPath({
					pack: ["reselect"],
					name: "Reselect",
					sub: "StateSelector",
					params: [
						makeTypeParam("TState"),
						makeTypeParam("Ret")
					]
				});

			case StateAndProps:
				TPath({
					pack: ["reselect"],
					name: "Reselect",
					sub: "StateAndMaybePropsSelector",
					params: [
						makeTypeParam("TState"),
						makeTypeParam("TProps"),
						makeTypeParam("Ret")
					]
				});
		}

		return EFunction(
			null,
			{
				args: args,
				expr: { expr: EBlock([]), pos: pos },
				params: params,
				ret: ret
			}
		);
	}

	static function makeArg(index:Int) {
		return {
			meta: [],
			name: 's$index',
			type: makeSelectorType(ARGS_TYPE_NAMES.charAt(index)),
			opt: false,
			value: null
		};
	}

	static function makeResultFunc(nArgs:Int) {
		var args = [];
		for (i in 0...nArgs) args.push(makeTPath(ARGS_TYPE_NAMES.charAt(i)));

		return {
			meta: [],
			name: "resultFunc",
			type: TFunction(args, makeTPath("Ret")),
			opt: false,
			value: null
		};
	}

	static function makeSelectorType(argType:String):ComplexType {
		return TPath({
			pack: ["reselect"],
			name: "Reselect",
			sub: "Selector",
			params: [
				makeTypeParam("TState"),
				makeTypeParam("TProps"),
				makeTypeParam(argType)
			]
		});
	}

	static function makeParam(name:String) {
		return {meta: [], name: name, params: [], constraints: []};
	}

	static function makeTypeParam(name:String):TypeParam {
		return TPType(makeTPath(name));
	}

	static function makeTPath(name:String, ?params:Array<TypeParam> = null):ComplexType {
		if (params == null) params = [];
		return TPath({name: name, pack: [], params: params});
	}
}
