// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFboWritableAttachment.h"
#import "LTRenderbuffer.h"

NS_ASSUME_NONNULL_BEGIN

/// Class extension that adds the private protocol \c LTFboWritableAttachment over
/// \c LTRenderbuffer.
@interface LTRenderbuffer () <LTFboWritableAttachment>
@end

NS_ASSUME_NONNULL_END
