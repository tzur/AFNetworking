// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTProgramPool.h"

#import "LTGLContext.h"
#import "LTProgram.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTProgramPool ()

/// Holds the current programs in the pool, keyed by their \c sourceIdentifier.
@property (readonly, nonatomic)
    NSMutableDictionary<NSString *, NSMutableArray<NSNumber *> *> *pool;

@end

@implementation LTProgramPool

- (instancetype)init {
  if (self = [super init]) {
    _pool = [NSMutableDictionary dictionary];
  }
  return self;
}

+ (nullable instancetype)currentPool {
  return [LTGLContext currentContext].programPool;
}

- (void)dealloc {
  [self flush];
}

- (void)flush {
  for (NSString *key in self.pool) {
    for (NSNumber *name in self.pool[key]) {
      glDeleteProgram(name.intValue);
    }
  }
  LTGLCheck(@"Failed deleting programs when deallocating program pool");

  [self.pool removeAllObjects];
}

- (GLuint)nameForIdentifier:(NSString *)identifier {
  NSMutableArray<NSNumber *> * _Nullable programs = self.pool[identifier];
  if (programs.count) {
    NSNumber *program = programs.lastObject;
    [programs removeLastObject];
    return program.unsignedIntValue;
  }

  GLuint program = glCreateProgram();
  LTAssert(program, @"Failed creating GL program");

  return program;
}

- (void)recycleName:(GLuint)name withIdentifier:(NSString *)identifier {
  NSMutableArray<NSNumber *> * _Nullable programs = self.pool[identifier];
  if (!programs) {
    programs = [NSMutableArray array];
    self.pool[identifier] = programs;
  }

  [programs addObject:@(name)];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, pool: %@>", self.class, self, self.pool];
}

@end

NS_ASSUME_NONNULL_END
