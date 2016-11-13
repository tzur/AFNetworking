// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "LTCompoundRandomAccessCollection.h"

#import "LTFastEnumerator.h"
#import "NSArray+Functional.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTCompoundRandomAccessCollection ()

/// Underlying collections.
@property (readonly, nonatomic) NSArray<id<LTRandomAccessCollection>> *collections;

/// Fast enumerator used to enable compound fast enumeration.
@property (strong, nonatomic) LTFastEnumerator *fastEnumerator;

@end

@implementation LTCompoundRandomAccessCollection

- (instancetype)initWithCollections:(NSArray<id<LTRandomAccessCollection>> *)collections {
  if (self = [super init]) {
    _collections = collections;
    _fastEnumerator = [collections.lt_enumerator flatten];
  }
  return self;
}

#pragma mark -
#pragma mark LTRandomAccessCollection
#pragma mark -

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
  return [self objectAtIndex:idx];
}

- (id)objectAtIndex:(NSUInteger)idx {
  NSUInteger runningIndex = idx;
  for (id<LTRandomAccessCollection> collection in self.collections) {
    if (collection.count > runningIndex) {
      return collection[runningIndex];
    }
    runningIndex -= collection.count;
  }
  [[NSException exceptionWithName:NSRangeException
                           reason:[NSString stringWithFormat:@"index %lu is out of bounds", idx]
                         userInfo:nil] raise];
  __builtin_unreachable();
}

- (BOOL)containsObject:(id)object {
  return [self indexOfObject:object] != NSNotFound;
}

- (NSUInteger)indexOfObject:(id)object {
  NSUInteger offset = 0;
  for (id<LTRandomAccessCollection> collection in self.collections) {
    NSUInteger index = [collection indexOfObject:object];
    if (index != NSNotFound) {
      return offset + index;
    }
    offset += collection.count;
  }
  return NSNotFound;
}

- (nullable id)firstObject {
  for (id<LTRandomAccessCollection> collection in self.collections) {
    id _Nullable firstObject = collection.firstObject;
    if (firstObject) {
      return firstObject;
    }
  }
  return nil;
}

- (nullable id)lastObject {
  for (id<LTRandomAccessCollection> collection in self.collections.reverseObjectEnumerator) {
    id _Nullable lastObject = collection.lastObject;
    if (lastObject) {
      return lastObject;
    }
  }
  return nil;
}

- (NSUInteger)count {
  NSUInteger count = 0;
  for (id<LTRandomAccessCollection> collection in self.collections) {
    count += collection.count;
  }
  return count;
}

#pragma mark -
#pragma mark NSFastEnumeration
#pragma mark -

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id *)buffer
                                    count:(NSUInteger)len {
  return [self.fastEnumerator countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (id)copyWithZone:(nullable NSZone *)zone {
  NSArray<id<LTRandomAccessCollection>> *copiedCollections = [self.collections
      lt_map:^id<LTRandomAccessCollection>(id<LTRandomAccessCollection> collection) {
        return [collection copyWithZone:zone];
      }];

  return [[self.class alloc] initWithCollections:copiedCollections];
}

@end

NS_ASSUME_NONNULL_END
