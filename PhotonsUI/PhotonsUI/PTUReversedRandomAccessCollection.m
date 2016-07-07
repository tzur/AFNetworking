// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUReversedRandomAccessCollection.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUReversedRandomAccessCollection ()

/// Underlying collection.
@property (readonly, nonatomic) id<LTRandomAccessCollection> collection;

@end

@implementation PTUReversedRandomAccessCollection

- (instancetype)initWithCollection:(id<LTRandomAccessCollection>)collection {
  if (self = [super init]) {
    _collection = collection;
  }
  return self;
}

#pragma mark -
#pragma mark LTRandomAccessCollection
#pragma mark -

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState __unused *)state
                                  objects:(__unsafe_unretained id  _Nonnull __unused *)buffer
                                    count:(NSUInteger __unused)len {
  LTMethodNotImplemented();
}

- (id)objectAtIndex:(NSUInteger)idx {
  return [self.collection objectAtIndex:[self reversedIndex:idx]];
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
  return [self objectAtIndex:idx];
}

- (BOOL)containsObject:(id)object {
  return [self.collection containsObject:object];
}

- (NSUInteger)indexOfObject:(id)anObject {
  return [self reversedIndex:[self.collection indexOfObject:anObject]];
}

- (nullable id)firstObject {
  return self.collection.lastObject;
}

- (nullable id)lastObject {
  return self.collection.firstObject;
}

- (NSUInteger)count {
  return self.collection.count;
}

- (NSUInteger)reversedIndex:(NSUInteger)index {
  return self.collection.count - index - 1;
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (id)copyWithZone:(nullable NSZone *)zone {
  return [self initWithCollection:[self.collection copyWithZone:zone]];
}

@end

NS_ASSUME_NONNULL_END
