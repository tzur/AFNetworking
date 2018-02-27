// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModelVersion.h"

NS_ASSUME_NONNULL_BEGIN

@class DVNBrushModel;

@interface DVNBrushModelVersion (TestBrushModel)

/// Returns a \c DVNBrushModel JSON dictionary for this instance, for testing purposes.
- (NSDictionary *)JSONDictionaryOfTestBrushModel;

/// Returns a \c DVNBrushModel for this instance, for testing purposes.
- (DVNBrushModel *)testBrushModel;

@end

NS_ASSUME_NONNULL_END
