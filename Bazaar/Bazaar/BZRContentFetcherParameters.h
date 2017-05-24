// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Contains information on how and from where the content should be fetched. Should be used as a
/// base class.
@interface BZRContentFetcherParameters : BZRModel <MTLJSONSerializing>

/// Content fetcher type, must be the name of a subclass of \c BZRProductContentFetcher.
@property (readonly, nonatomic) NSString *type;

@end

NS_ASSUME_NONNULL_END
