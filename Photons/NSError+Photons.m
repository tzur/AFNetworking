// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSError+Photons.h"

#import <LTKit/NSError+LTKit.h>

NS_ASSUME_NONNULL_BEGIN

NSString * kPTNErrorAssociatedObjectKey = @"AssociatedObject";

@implementation NSError (Photons)

+ (instancetype)ptn_errorWithCode:(NSInteger)code associatedObject:(id<PTNObject>)associatedObject {
  return [NSError lt_errorWithCode:code userInfo:@{
    kPTNErrorAssociatedObjectKey: (id)associatedObject ?: [NSNull null]
  }];
}

- (nullable id<PTNObject>)ptn_associatedObject {
  return self.userInfo[kPTNErrorAssociatedObjectKey] != [NSNull null] ?
      self.userInfo[kPTNErrorAssociatedObjectKey] : nil;
}

@end

NS_ASSUME_NONNULL_END
