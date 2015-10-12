// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSErrorCodes+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNObject;

/// Key containing the Photons object associated with the error.
extern NSString * kPTNErrorAssociatedObjectKey;

@interface NSError (Photons)

/// Creates an error with Lightricks' domain, given error code and the associated object.
+ (instancetype)ptn_errorWithCode:(NSInteger)code associatedObject:(id<PTNObject>)associatedObject;

/// Photons object associated with the error.
@property (readonly, nonatomic, nullable) id<PTNObject> ptn_associatedObject;

@end

NS_ASSUME_NONNULL_END
