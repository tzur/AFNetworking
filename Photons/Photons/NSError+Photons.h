// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSErrorCodes+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNDescriptor;

/// Key containing the Photons descriptor associated with the error.
extern NSString * kPTNErrorAssociatedDescriptorKey;

/// Key containing the Photons descriptors associated with the error.
extern NSString * kPTNErrorAssociatedDescriptorsKey;

@interface NSError (Photons)

/// Creates an error with Lightricks' domain, given error code and the associated descriptor.
+ (instancetype)ptn_errorWithCode:(NSInteger)code
             associatedDescriptor:(id<PTNDescriptor>)associatedDescriptor;

/// Creates an error with Lightricks' domain, given error code and the associated descriptor array.
+ (instancetype)ptn_errorWithCode:(NSInteger)code
            associatedDescriptors:(NSArray<id<PTNDescriptor>> *)associatedDescriptors;

/// Creates an error with Lightricks' domain, given error code, associated descriptor and underlying
/// error.
+ (instancetype)ptn_errorWithCode:(NSInteger)code
             associatedDescriptor:(id<PTNDescriptor>)associatedDescriptor
                  underlyingError:(nullable NSError *)underlyingError;

/// Creates an error with Lightricks' domain, given error code, associated descriptor array and
/// underlying error.
+ (instancetype)ptn_errorWithCode:(NSInteger)code
            associatedDescriptors:(NSArray<id<PTNDescriptor>> *)associatedDescriptors
                  underlyingError:(nullable NSError *)underlyingError;

/// Creates an error with Lightricks' domain, given error code, associated descriptor and
/// description.
+ (instancetype)ptn_errorWithCode:(NSInteger)code
             associatedDescriptor:(id<PTNDescriptor>)associatedDescriptor
                      description:(NSString *)description;

/// Creates an error with Lightricks' domain, given error code, associated descriptors and
/// description.
+ (instancetype)ptn_errorWithCode:(NSInteger)code
            associatedDescriptors:(NSArray<id<PTNDescriptor>> *)associatedDescriptors
                      description:(NSString *)description;

/// Photons descriptor associated with the error.
@property (readonly, nonatomic, nullable) id<PTNDescriptor> ptn_associatedDescriptor;

/// Photons descriptors associated with the error.
@property (readonly, nonatomic, nullable) NSArray<id<PTNDescriptor>> *ptn_associatedDescriptors;

@end

NS_ASSUME_NONNULL_END
