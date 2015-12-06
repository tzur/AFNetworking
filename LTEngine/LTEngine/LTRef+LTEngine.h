// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <LTKit/LTRef.h>

#import <CoreText/CoreText.h>
#import <CoreVideo/CoreVideo.h>
#import <ImageIO/ImageIO.h>

#ifdef __cplusplus

namespace lt {

// Core Video.
template <> struct IsCoreFoundationObjectRef<CVPixelBufferRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CVOpenGLESTextureCacheRef> : public std::true_type {};

// Core Text.
template <> struct IsCoreFoundationObjectRef<CTFontRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CTFramesetterRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CTFrameRef> : public std::true_type {};

// Image IO.
template <> struct IsCoreFoundationObjectRef<CGImageDestinationRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CGImageSourceRef> : public std::true_type {};

} // namespace lt

#endif
