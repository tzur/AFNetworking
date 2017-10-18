// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTColorTransferProcessor.h"

NS_ASSUME_NONNULL_BEGIN

/// Unoptimized version of the \c LTColorTransferProcessor, which is more readable and can be used
/// for testing purposes. Implementation replaces all Accelerate framework code with OpenCV and STL
/// making it slower but easier to follow and understand.
@interface LTTestColorTransferProcessor : LTColorTransferProcessor
@end

NS_ASSUME_NONNULL_END
