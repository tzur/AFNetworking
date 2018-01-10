// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <FBTweak/FBTweakEnabled.h>
#import <FBTweak/FBTweakInlineInternal.h>

#import "FBTweak+RACSignalSupport.h"

#if !FB_TWEAK_ENABLED

#define _SHKTweakSignal(category_, collection_, name_, ...) \
  ([RACSignal return:__FBTweakDefault(__VA_ARGS__)])

#else

#define _SHKTweakSignalWithoutRange(category_, collection_, name_, default_) \
((^{ \
  FBTweak *__signal_tweak = _FBTweakInlineWithoutRange(category_, collection_, name_, \
      (id)default_); \
  return _SHKTweakSignalInternal(__signal_tweak); \
})())

#define _SHKTweakSignalWithRange(category_, collection_, name_, default_, min_, max_) \
((^{ \
  FBTweak *__signal_tweak = \
      _FBTweakInlineWithRange(category_, collection_, name_, (id)default_, min_, max_); \
  return _SHKTweakSignalInternal(__signal_tweak); \
})())

#define _SHKTweakSignalWithPossible(category_, collection_, name_, default_, possible_) \
((^{ \
  FBTweak *__signal_tweak = \
      _FBTweakInlineWithPossible(category_, collection_, name_, (id)default_, possible_); \
  return _SHKTweakSignalInternal(__signal_tweak); \
})())

#define _SHKTweakSignalInternal(tweak_) \
((^{ \
  return [tweak_ shk_valueChanged]; \
})())

#define _SHKTweakSignal(category_, collection_, name_, ...) \
  _FBTweakDispatch(_SHKTweakSignalWithoutRange, _SHKTweakSignalWithRange, \
      _SHKTweakSignalWithPossible, __VA_ARGS__)(category_, collection_, name_, __VA_ARGS__)

#endif
