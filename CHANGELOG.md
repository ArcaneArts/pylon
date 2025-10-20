## 3.2.0
* Breaking: Removed beamer and url features to stop dep conflicts
* Documentation changes

## 3.1.11
* Fixes & Docs

## 3.1.10
* Beamer Test & Fix 

## 3.1.9
* ADD `Pylon.pushReplacement`
* ADD `Pylon.pushAndRemoveUntil`

## 3.1.7
* ADD `PylonRemove` to remove a pylon from the context

## 3.1.6
* Fix /#/ port navigation

## 3.1.5
* Add Conduits

## 3.1.4
* Attempt to fix wasm builds with js_interop conditional import

## 3.1.3
* Fix pylon error port

## 3.1.2
* Support codecs without specific types by casting late on value instead of on codec.

## 3.1.1
* Move codecs to [pylon_codec](https://pub.dev/packages/pylon_codec) package and endorse it.

## 3.1.0
* Added error widget property on PylonFuture
* Added codecs & PylonCodec registration into Pylon
* Added PylonPort used for pushing data into the browser address bar & pulling data down from the address bar if the data is unavailable on context.

## 3.0.5
* Allow localized pylons that dont get picked up in mirror.

## 3.0.4
* Bugfixes

## 3.0.3
* Allow pylons to be accessed via runtime type (parameter) by looking at all visible pylons (same as mirror) and grabbing the first visible pylon with the matching value type

## 3.0.2
* Fixes

## 3.0.1
* Fixes

## 3.0.0
* BREAKING: Pylon has been rewritten to be more reliable and allow modifications

## 2.0.4
* FIX Using a stream builder which builds a pylon with an updated value without using pylon streams will now update the pylon correctly
* Added debugging by pylon types with dPylonDebug set of types tag

## 2.0.3
* FIX State Loss when nesting multiple pylons inside of each other with active value streams
* FIX Pylon push overwriting previous values in stacked same-type pylons breaking the tree logic

## 2.0.2
* Getting or Streaming Pylons will also search nullable pylon types

## 2.0.1
* Pylons can now receive an input stream instead of relying on the upstream to pump in data
* When pylons are given a stream, they can connect it to other pylons across screens and still update
* Added an option to disable focus updates while keeping childUpdates enabled

## 2.0.0
* BREAKING: Rewritten to be more reliable and allow modifications
* Please read README & Examples!

## 1.0.4
* FIX: When mirroring, skips already existing types to prevent a previous pylon overwritten from accidentally becoming the new value

## 1.0.3
* Added .withPylonNullable for futures and streams

## 1.0.2

* Attempt to find T? when searching for T with pylon<T>()
* Added pylon<T>(or: T) to provide a default value if the pylon is not found

## 1.0.1

* Stream Extensions

## 1.0.0

* Initial Release
