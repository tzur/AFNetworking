// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFboPool.h"

#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

/// Represents the texture and its level which is bound to a framebuffer.
@interface LTFboBindPair : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new bind pair with the texture's name and the level the framebuffer is bound to.
- (instancetype)initWithName:(GLuint)name andLevel:(NSUInteger)level NS_DESIGNATED_INITIALIZER;

/// Name of the texture.
@property (readonly, nonatomic) GLuint name;

/// Level of the texture.
@property (readonly, nonatomic) NSUInteger level;

@end

@implementation LTFboBindPair

- (instancetype)init {
  return nil;
}

- (instancetype)initWithName:(GLuint)name andLevel:(NSUInteger)level {
  if (self = [super init]) {
    _name = name;
    _level = level;
  }
  return self;
}

- (NSUInteger)hash {
  return _name + (_level << 16);
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[LTFboBindPair class]]) {
    return NO;
  }

  LTFboBindPair *pair = object;
  return self.name == pair.name && self.level == pair.level;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, name: %d, level: %lu>", self.class, self,
          self.name, (unsigned long)self.level];
}

@end

@interface LTFboPool ()

/// Maps between an \c LTFboBindPair and its associated \c LTFbo, which is held weakly.
@property (strong, nonatomic) NSMapTable *bindPairToFbo;

@end

@implementation LTFboPool

- (instancetype)init {
  if (self = [super init]) {
    self.bindPairToFbo = [NSMapTable strongToWeakObjectsMapTable];
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
  LTFboBindPair *bindPair = [[LTFboBindPair alloc] initWithName:texture.name andLevel:level];

  LTFbo *existingFbo = [self.bindPairToFbo objectForKey:bindPair];
  if (existingFbo) {
    return existingFbo;
  }

  LTFbo *newFbo = [[LTFbo alloc] initWithTexture:texture level:level];
  [self.bindPairToFbo setObject:newFbo forKey:bindPair];

  return newFbo;
}

@end

NS_ASSUME_NONNULL_END
