// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFboPool.h"

#import "LTFbo.h"
#import "LTFboAttachment.h"
#import "LTGLContext.h"
#import "LTRenderbuffer.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

/// Represents the texture and its level which is bound to a framebuffer.
@interface LTFboAttachmentDescriptor : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new attachment descriptor with the attachment type, the attachment's name and the
/// level the framebuffer is attached to.
- (instancetype)initWithType:(LTFboAttachmentType)type name:(GLuint)name
                    andLevel:(NSUInteger)level NS_DESIGNATED_INITIALIZER;

/// Type of binding.
@property (readonly, nonatomic) LTFboAttachmentType type;

/// Name of the texture.
@property (readonly, nonatomic) GLuint name;

/// Level of the texture.
@property (readonly, nonatomic) NSUInteger level;

@end

@implementation LTFboAttachmentDescriptor

- (instancetype)init {
  return nil;
}

- (instancetype)initWithType:(LTFboAttachmentType)type name:(GLuint)name
                    andLevel:(NSUInteger)level {
  if (self = [super init]) {
    _type = type;
    _name = name;
    _level = level;
  }
  return self;
}

- (NSUInteger)hash {
  return _type + (_name << 2) + (_level << 16);
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[LTFboAttachmentDescriptor class]]) {
    return NO;
  }

  LTFboAttachmentDescriptor *descriptor = object;
  return self.type == descriptor.type && self.name == descriptor.name &&
      self.level == descriptor.level;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, type: %lu, name: %d, level: %lu>", self.class, self,
          (unsigned long)self.type, self.name, (unsigned long)self.level];
}

@end

@interface LTFboPool ()

/// Maps between an \c LTFboAttachmentDescriptor and its associated \c LTFbo, which is held weakly.
@property (strong, nonatomic) NSMapTable *attachmentDescriptorToFbo;

@end

@implementation LTFboPool

- (instancetype)init {
  if (self = [super init]) {
    self.attachmentDescriptorToFbo = [NSMapTable strongToWeakObjectsMapTable];
  }
  return self;
}

+ (nullable instancetype)currentPool {
  return [LTGLContext currentContext].fboPool;
}

- (LTFbo *)fboWithTexture:(LTTexture *)texture {
  return [self fboWithTexture:texture level:0];
}

- (LTFbo *)fboWithTexture:(LTTexture *)texture level:(NSUInteger)level {
  LTFboAttachmentDescriptor *descriptor = [[LTFboAttachmentDescriptor alloc]
                                           initWithType:LTFboAttachmentTypeTexture2D
                                           name:texture.name
                                           andLevel:level];

  LTFbo *existingFbo = [self.attachmentDescriptorToFbo objectForKey:descriptor];
  if (existingFbo) {
    return existingFbo;
  }

  LTFbo *newFbo = [[LTFbo alloc] initWithTexture:texture level:level];
  [self.attachmentDescriptorToFbo setObject:newFbo forKey:descriptor];

  return newFbo;
}

- (LTFbo *)fboWithRenderbuffer:(LTRenderbuffer *)renderbuffer {
  LTFboAttachmentDescriptor *descriptor = [[LTFboAttachmentDescriptor alloc]
                                           initWithType:LTFboAttachmentTypeRenderbuffer
                                           name:renderbuffer.name
                                           andLevel:0];

  LTFbo *existingFbo = [self.attachmentDescriptorToFbo objectForKey:descriptor];
  if (existingFbo) {
    return existingFbo;
  }

  LTFbo *newFbo = [[LTFbo alloc] initWithRenderbuffer:renderbuffer];
  [self.attachmentDescriptorToFbo setObject:newFbo forKey:descriptor];

  return newFbo;
}

@end

NS_ASSUME_NONNULL_END
