// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTRenderbuffer.h"

NS_ASSUME_NONNULL_BEGIN

/// Category augmenting \c LTRenderbuffer with private API, which allows disposing the OGL backing
/// object.
@interface LTRenderbuffer ()

/// Deletes the OGL renderbuffer backing object and unbind it if necessary, additionally it sets the
/// \c name to \c 0. If necessary it detaches the OGL renderbuffer from any attachment points in OGL
/// framebuffer it's attached to. This method is normally called when \c LTFbo is deallocated. Any
/// subsequent calls to this method will be ignored. After calling this method it's forbidden to
/// perform any OGL operation on this instance.
- (void)dispose;

@end

NS_ASSUME_NONNULL_END
