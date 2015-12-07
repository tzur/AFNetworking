// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSError+Photons.h"

#import <LTKit/NSError+LTKit.h>

NS_ASSUME_NONNULL_BEGIN

NSString * kPTNErrorAssociatedDescriptorKey = @"AssociatedDescriptor";

@implementation NSError (Photons)

+ (instancetype)ptn_errorWithCode:(NSInteger)code
             associatedDescriptor:(id<PTNDescriptor>)associatedDescriptor {
  return [NSError lt_errorWithCode:code userInfo:@{
    kPTNErrorAssociatedDescriptorKey: (id)associatedDescriptor ?: [NSNull null]
  }];
}

- (nullable id<PTNDescriptor>)ptn_associatedDescriptor {
  return self.userInfo[kPTNErrorAssociatedDescriptorKey] != [NSNull null] ?
      self.userInfo[kPTNErrorAssociatedDescriptorKey] : nil;
}

@end

NS_ASSUME_NONNULL_END
