// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "PTNAudiovisualAsset.h"
#import "PTNDataAsset.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol for an audiovisual asset backed up by \c NSData.
@protocol PTNAVDataAsset <PTNDataAsset, PTNAudiovisualAsset>
@end

NS_ASSUME_NONNULL_END
