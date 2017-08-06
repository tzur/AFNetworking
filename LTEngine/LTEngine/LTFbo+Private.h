// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTFbo.h"

NS_ASSUME_NONNULL_BEGIN

/// Category augmenting \c LTFbo with private API, which allows disposing the OGL backing object.
@interface LTFbo ()

/// Deletes the OGL framebuffer backing object and unbinds it if necessary, additionally it sets the
/// \c name to \c 0. This method is normally called when \c LTFbo is deallocated. Any subsequent
/// calls to this method will be ignored. After calling this method it's forbidden to perform any
/// OGL related operation on this instance.
- (void)dispose;

@end

NS_ASSUME_NONNULL_END
