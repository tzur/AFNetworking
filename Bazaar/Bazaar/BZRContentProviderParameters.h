// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Contains information on how and from where the content should be fetched. Should be used as a
/// base class and not be instantiated.
@interface BZRContentProviderParameters : BZRModel <MTLJSONSerializing>
@end

NS_ASSUME_NONNULL_END
