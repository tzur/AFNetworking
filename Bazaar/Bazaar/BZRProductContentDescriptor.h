// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Contains information on how and from where the content should be fetched.
@interface BZRProductContentDescriptor : BZRModel <MTLJSONSerializing>

/// Name of the class with which to fetch the content. Must conform to \c BZRProductContentProvider
/// protocol.
@property (readonly, nonatomic) NSString *contentProvider;

/// Parameters needed for the \c contentProvider.
@property (readonly, nonatomic, nullable) NSDictionary *contentProviderParameters;

@end

NS_ASSUME_NONNULL_END
