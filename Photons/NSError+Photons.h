// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSErrorCodes+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNDescriptor;

/// Key containing the Photons descriptor associated with the error.
extern NSString * kPTNErrorAssociatedDescriptorKey;

@interface NSError (Photons)

/// Creates an error with Lightricks' domain, given error code and the associated descriptor.
+ (instancetype)ptn_errorWithCode:(NSInteger)code
             associatedDescriptor:(id<PTNDescriptor>)associatedDescriptor;

/// Photons descriptor associated with the error.
@property (readonly, nonatomic, nullable) id<PTNDescriptor> ptn_associatedDescriptor;

@end

NS_ASSUME_NONNULL_END
