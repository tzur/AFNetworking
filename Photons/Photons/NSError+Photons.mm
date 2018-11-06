// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSError+Photons.h"

#import <LTKit/NSError+LTKit.h>

NS_ASSUME_NONNULL_BEGIN

NSString * kPTNErrorAssociatedDescriptorKey = @"AssociatedDescriptor";
NSString * kPTNErrorAssociatedDescriptorsKey = @"AssociatedDescriptors";

@implementation NSError (Photons)

+ (instancetype)ptn_errorWithCode:(NSInteger)code
             associatedDescriptor:(id<PTNDescriptor>)associatedDescriptor {
  return [NSError lt_errorWithCode:code userInfo:@{
    kPTNErrorAssociatedDescriptorKey: (id)associatedDescriptor ?: [NSNull null]
  }];
}

+ (instancetype)ptn_errorWithCode:(NSInteger)code
            associatedDescriptors:(NSArray<id<PTNDescriptor>> *)associatedDescriptors {
  return [NSError lt_errorWithCode:code userInfo:@{
    kPTNErrorAssociatedDescriptorsKey: associatedDescriptors ?: [NSNull null]
  }];
}

+ (instancetype)ptn_errorWithCode:(NSInteger)code
             associatedDescriptor:(id<PTNDescriptor>)associatedDescriptor
                  underlyingError:(nullable NSError *)underlyingError {
  return [NSError lt_errorWithCode:code userInfo:@{
    kPTNErrorAssociatedDescriptorKey: (id)associatedDescriptor ?: [NSNull null],
    NSUnderlyingErrorKey: underlyingError ?: [NSError ptn_nullValueGivenError]
  }];
}

+ (instancetype)ptn_errorWithCode:(NSInteger)code
            associatedDescriptors:(NSArray<id<PTNDescriptor>> *)associatedDescriptors
                  underlyingError:(nullable NSError *)underlyingError {
  return [NSError lt_errorWithCode:code userInfo:@{
    kPTNErrorAssociatedDescriptorsKey: associatedDescriptors ?: [NSNull null],
    NSUnderlyingErrorKey: underlyingError ?: [NSError ptn_nullValueGivenError]
  }];
}

+ (instancetype)ptn_errorWithCode:(NSInteger)code
             associatedDescriptor:(id<PTNDescriptor>)associatedDescriptor
                      description:(NSString *)description {
  return [NSError lt_errorWithCode:code userInfo:@{
    kPTNErrorAssociatedDescriptorKey: (id)associatedDescriptor ?: [NSNull null],
    kLTErrorDescriptionKey: description ?: [NSNull null]
  }];
}

+ (instancetype)ptn_errorWithCode:(NSInteger)code
            associatedDescriptors:(NSArray<id<PTNDescriptor>> *)associatedDescriptors
                      description:(NSString *)description {
  return [NSError lt_errorWithCode:code userInfo:@{
    kPTNErrorAssociatedDescriptorsKey: associatedDescriptors ?: [NSNull null],
    kLTErrorDescriptionKey: description ?: [NSNull null]
  }];
}

+ (instancetype)ptn_nullValueGivenError {
  return [NSError lt_errorWithCode:LTErrorCodeNullValueGiven];
}

- (nullable id<PTNDescriptor>)ptn_associatedDescriptor {
  return self.userInfo[kPTNErrorAssociatedDescriptorKey] != [NSNull null] ?
      self.userInfo[kPTNErrorAssociatedDescriptorKey] : nil;
}

- (nullable NSArray<id<PTNDescriptor>> *)ptn_associatedDescriptors {
  return self.userInfo[kPTNErrorAssociatedDescriptorsKey] != [NSNull null] ?
      self.userInfo[kPTNErrorAssociatedDescriptorsKey] : nil;
}

@end

NS_ASSUME_NONNULL_END
