// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <FBTweak/FBTweakEnabled.h>
#import <FBTweak/FBTweakInlineInternal.h>

#import "FBMutableTweak+RACSignalSupport.h"

#if !FB_TWEAK_ENABLED

#define _SHKTweakSignal(category, collection, name, ...) \
  ([RACSignal return:__FBTweakDefault(__VA_ARGS__)])

#else

#define _SHKTweakSignalWithoutRange(category, collection, name, default) \
((^{ \
  FBPersistentTweak *signalTweak = _FBTweakInlineWithoutRange(category, collection, name, \
      (id)default); \
  return _SHKTweakSignalInternal(signalTweak); \
})())

#define _SHKTweakSignalWithRange(category, collection, name, default, min, max) \
((^{ \
  FBPersistentTweak *signalTweak = \
      _FBTweakInlineWithRange(category, collection, name, (id)default, min, max); \
  return _SHKTweakSignalInternal(signalTweak); \
})())

#define _SHKTweakSignalWithPossible(category, collection, name, default, possible) \
((^{ \
  FBPersistentTweak *signalTweak = \
      _FBTweakInlineWithPossible(category, collection, name, (id)default, possible); \
  return _SHKTweakSignalInternal(signalTweak); \
})())

#define _SHKTweakSignalInternal(tweak) \
((^{ \
  return [tweak shk_valueChanged]; \
})())

#define _SHKTweakSignal(category, collection, name, ...) \
  _FBTweakDispatch(_SHKTweakSignalWithoutRange, _SHKTweakSignalWithRange, \
      _SHKTweakSignalWithPossible, __VA_ARGS__)(category, collection, name, __VA_ARGS__)

#endif
