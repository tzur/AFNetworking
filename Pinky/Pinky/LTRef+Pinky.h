// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import <CoreVideo/CoreVideo.h>
#import <LTKit/LTRef.h>

#ifdef __cplusplus

namespace lt {

// Core Video.
#if defined(__OBJC__) && COREVIDEO_SUPPORTS_METAL
  template <> struct IsCoreFoundationObjectRef<CVMetalTextureCacheRef> : public std::true_type {};
#endif

} // namespace lt

#endif
