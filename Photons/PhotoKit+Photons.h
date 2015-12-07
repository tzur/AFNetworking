// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Photos/Photos.h>

#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface PHAsset (Photons) <PTNDescriptor>
@end

@interface PHCollection (Photons) <PTNDescriptor>
@end

NS_ASSUME_NONNULL_END
