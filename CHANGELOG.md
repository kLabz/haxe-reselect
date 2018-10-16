# Changelog

## 0.0.5 (2018-10-16)

* Better macro-in-macro fix for haxe 4 preview 5

## 0.0.4 (2018-10-02)

* Fix macro-in-macro call.
* Added `-D reselect_global` to use global Reselect (thanks to cambiata's [PR](https://github.com/kLabz/haxe-reselect/pull/1)).

## 0.0.3 (2017-11-17)

* Moved tests sources to avoid conflicts when using lib.

## 0.0.2 (2017-11-05)

* Basic implementation of the complete Reselect API; needs more work with the typing.
* Added `Reselect.createSelectorCreator(...)` and its tests.
* Added `Reselect.createStructuredSelector(...)` and its tests.
* Added `Reselect.defaultMemoize(...)` and its tests.
* Added `Reselect.defaultEqualityCheck(...)`.

## 0.0.1 (2017-11-05)

* Added `Reselect.createSelector(...)` and its tests.
