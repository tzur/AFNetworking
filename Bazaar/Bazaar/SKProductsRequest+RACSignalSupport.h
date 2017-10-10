// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRRequestStatusSignal.h"

NS_ASSUME_NONNULL_BEGIN

/// Adds reactive interface to \c SKProductsRequest.
///
/// @note As a side effect of this method the receiver's delegate will be replaced. Setting the
/// receiver's \c delegate property afterward is considered undefined behavior.
@interface SKProductsRequest (RACSignalSupport) <BZRRequestStatusSignal>
@end

NS_ASSUME_NONNULL_END
