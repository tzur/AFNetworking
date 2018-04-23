// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "LTMappingRandomAccessCollection.h"

#import "LTFastEnumerator.h"

@interface LTMappingRandomAccessCollection ()

/// Block used for mapping of the objects of the underlying collection.
@property (copy, nonatomic) LTRandomAccessCollectionMappingBlock forwardMap;

/// Block used for mapping of the returned values back to objects of the underlying collection.
@property (copy, nonatomic) LTRandomAccessCollectionMappingBlock reverseMap;

/// Fast enumerator used to enable mapped fast enumeration.
@property (strong, nonatomic) LTFastEnumerator *fastEnumerator;

@end

@implementation LTMappingRandomAccessCollection

- (instancetype)initWithCollection:(id<LTRandomAccessCollection>)collection
                   forwardMapBlock:(LTRandomAccessCollectionMappingBlock)forwardMap
                   reverseMapBlock:(LTRandomAccessCollectionMappingBlock)reverseMap {
  LTParameterAssert(forwardMap && reverseMap);
  if (self = [super init]) {
    _collection = collection;
    _forwardMap = [forwardMap copy];
    _reverseMap = [reverseMap copy];

    _fastEnumerator = [[[LTFastEnumerator alloc] initWithSource:self.collection] map:forwardMap];
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
  return nn(self.forwardMap(self.collection[idx]));
}

- (BOOL)containsObject:(id)object {
  return [self indexOfObject:object] != NSNotFound;
}

- (NSUInteger)indexOfObject:(id)object {
  id _Nullable underlyingObject = self.reverseMap(object);
  if (!underlyingObject) {
    return NSNotFound;
  }

  return [self.collection indexOfObject:nn(underlyingObject)];
}

- (nullable id)firstObject {
  return self.count ? self[0] : nil;
}

- (nullable id)lastObject {
  return self.count ? self[self.collection.count - 1] : nil;
}

- (NSUInteger)count {
  return self.collection.count;
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

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return [[self.class alloc] initWithCollection:[self.collection copyWithZone:zone]
                                forwardMapBlock:self.forwardMap reverseMapBlock:self.reverseMap];
}

@end
