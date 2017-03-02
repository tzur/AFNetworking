// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTFboAttachmentInfo.h"

#import "LTFboAttachable.h"
#import "LTRenderbuffer.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTFboAttachmentInfo

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithAttachable:(id<LTFboAttachable>)attachable level:(GLint)level {
  if (self = [super init]) {
    _attachable = attachable;
    _level = level;
  }
  return self;
}

+ (instancetype)withAttachable:(id<LTFboAttachable>)attachable {
  return [[self alloc] initWithAttachable:attachable level:0];
}

+ (instancetype)withAttachable:(id<LTFboAttachable>)attachable level:(GLint)level {
  LTParameterAssert(attachable.attachableType == LTFboAttachableTypeTexture2D,
                    @"Attachable (%@) must be of LTFboAttachableTypeTexture2D type", attachable);
  auto texture = (LTTexture *)attachable;
  LTParameterAssert(level <= texture.maxMipmapLevel,
                    @"Attachable level %d must not greater than %d", level, texture.maxMipmapLevel);
  return [[self alloc] initWithAttachable:attachable level:level];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, attachable: %@, level: %lu>", [self class], self,
          self.attachable, (unsigned long)self.level];
}

@end

NS_ASSUME_NONNULL_END
