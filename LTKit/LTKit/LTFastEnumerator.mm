// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFastEnumerator.h"

#import <pthread/pthread.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark LTFastEnumeratorState
#pragma mark -

/// Maximal number of elements that will be returned in every call to
/// \c countByEnumeratingWithState:state:count:. This was set based on the common number that is
/// given by the ObjC runtime itself, but it may change on different architectures.
static const int kBufferSize = 16;

/// Holds the fast enumerator state. This external state is required since an additional
/// \c NSFastEnumerationState is required to hold the original source state, and because the objects
/// that are returned are placed on the stack and are \c __unsafe_unretained, so they must be
/// retained.
@interface LTFastEnumeratorState : NSObject {
@public
  __strong id _buffer[kBufferSize];

@private
  NSFastEnumerationState _sourceState;
}

/// Returns a new or exisitng state associated with the given \c enumerator.
+ (instancetype)stateForEnumerator:(LTFastEnumerator *)enumerator;

/// Resets the state by zeroing out the \c sourceState and releasing all objects that are held by
/// this object.
- (void)reset;

/// Destroys the state and removes it from memory.
- (void)destroy;

/// Enumerator this state is associated with.
@property (weak, nonatomic) LTFastEnumerator *enumerator;

/// Fast enumeration state of the source collection.
@property (readonly, nonatomic) NSFastEnumerationState *sourceState;

/// Buffer for objects as __unsafe_unretained.
@property (readonly, nonatomic) __unsafe_unretained id *unsafeBuffer;

/// Buffer for objects as __strong.
@property (readonly, nonatomic) __strong id *strongBuffer;

@end

#pragma mark -
#pragma mark LTFastEnumerator
#pragma mark -

@implementation LTFastEnumeratorState

- (instancetype)initWithEnumerator:(LTFastEnumerator *)enumerator {
  if (self = [super init]) {
    _enumerator = enumerator;
  }
  return self;
}

+ (instancetype)stateForEnumerator:(LTFastEnumerator *)enumerator {
  const void *key = pthread_self();

  LTFastEnumeratorState *state = objc_getAssociatedObject(enumerator, key);
  if (state) {
    return state;
  }

  LTFastEnumeratorState *newState = [[LTFastEnumeratorState alloc] initWithEnumerator:enumerator];
  objc_setAssociatedObject(enumerator, key, newState, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  return newState;
}

- (void)reset {
  memset(&_sourceState, 0, sizeof(_sourceState));

  for (NSUInteger i = 0; i < kBufferSize; ++i) {
    _buffer[i] = nil;
  }
}

- (void)destroy {
  [self reset];

  if (self.enumerator) {
    const void *key = pthread_self();
    objc_setAssociatedObject(nn(self.enumerator), key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
}

- (__unsafe_unretained id *)unsafeBuffer {
  return (__unsafe_unretained id *)(void *)_buffer;
}

- (__strong id *)strongBuffer {
  return _buffer;
}

- (NSFastEnumerationState *)sourceState {
  return &_sourceState;
}

@end

/// Current state of the enumeration. To be set to the \c state field of the
/// \c NSFastEnumerationState struct.
typedef NS_ENUM(unsigned long, LTEnumerationState) {
  /// Enumeration has not been started yet.
  LTEnumerationStateInitial = 0,
  /// Enumeration has been started.
  LTEnumerationStateStarted
};

/// Last count that was returned by the source.
static const NSUInteger kSourceCountKey = 0;

/// Index of item returned by the source that has not been handled yet.
static const NSUInteger kSourceIndexKey = 1;

/// Index of item in the current enumeration being enumerated.
static const NSUInteger kSourceCurrentValuesKey = 2;

typedef NSUInteger (^LTFastEnumeratorOperationBlock)(NSFastEnumerationState *state,
                                                     __unsafe_unretained id _Nonnull sourceItems[],
                                                     __strong id _Nonnull outputItems[],
                                                     NSUInteger outputItemsCount);

@interface LTFastEnumerator ()

/// Operation to perform on \c source.
@property (copy, nonatomic, nullable) LTFastEnumeratorOperationBlock operation;

@end

@implementation LTFastEnumerator

- (instancetype)initWithSource:(id<NSFastEnumeration>)source {
  return [self initWithSource:source operation:nil];
}

- (instancetype)initWithSource:(id<NSFastEnumeration>)source
                     operation:(nullable LTFastEnumeratorOperationBlock)operation {
  if (self = [super init]) {
    _source = source;
    _operation = operation;
  }
  return self;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id __unused *)buffer
                                    count:(NSUInteger)len {
  // No operation - directly pass arguments to source.
  if (!self.operation) {
    return [self.source countByEnumeratingWithState:state objects:buffer count:len];
  }

  LTFastEnumeratorState *ourState = [LTFastEnumeratorState stateForEnumerator:self];
  NSFastEnumerationState *sourceState = ourState.sourceState;

  // Initial state - fetch objects from source and set our external state.
  if (state->state == LTEnumerationStateInitial) {
    [ourState reset];

    NSUInteger sourceCount = [self.source countByEnumeratingWithState:sourceState objects:buffer
                                                                count:len];

    state->state = LTEnumerationStateStarted;
    state->itemsPtr = ourState.unsafeBuffer;
    state->mutationsPtr = sourceState->mutationsPtr;
    state->extra[kSourceCountKey] = sourceCount;
    state->extra[kSourceIndexKey] = 0;
  }

  NSUInteger count = 0;
  do {
    // No items were returned from the source, so there's no job left to be done.
    if (!state->extra[kSourceCountKey]) {
      [ourState destroy];
      return 0;
    }

    // All items has been processed, try to fetch more.
    if (state->extra[kSourceCountKey] == state->extra[kSourceIndexKey]) {
      NSUInteger sourceCount = [self.source countByEnumeratingWithState:sourceState objects:buffer
                                                                  count:len];
      state->extra[kSourceCountKey] = sourceCount;
      state->extra[kSourceIndexKey] = 0;
    }

    // Call the internal enumerator.
    count = self.operation(state, sourceState->itemsPtr, ourState.strongBuffer, kBufferSize);
  } while (!count);

  return count;
}

- (LTFastEnumerator *)map:(NS_NOESCAPE LTFastMapEnumerationBlock)block {
  LTFastEnumeratorOperationBlock map = ^NSUInteger(NSFastEnumerationState *state,
                                                   __unsafe_unretained id _Nonnull sourceItems[],
                                                   __strong id _Nonnull outputItems[],
                                                   NSUInteger outputItemsCount) {
    NSUInteger count = 0;
    NSUInteger sourceIndex = state->extra[kSourceIndexKey];

    while (count < outputItemsCount && sourceIndex < state->extra[kSourceCountKey]) {
      outputItems[count] = block(sourceItems[sourceIndex]);
      ++count;
      ++sourceIndex;
    }

    state->extra[kSourceIndexKey] = sourceIndex;

    return count;
  };

  return [[LTFastEnumerator alloc] initWithSource:self operation:map];
}

- (LTFastEnumerator *)flatMap:(NS_NOESCAPE LTFastFlatMapEnumerationBlock)block {
  // Holds the current enumeration that is being flattened.
  __block _Nullable id<NSFastEnumeration> currentValues;

  LTFastEnumeratorOperationBlock flatMap = ^NSUInteger(NSFastEnumerationState *state,
      __unsafe_unretained id _Nonnull sourceItems[], __strong id _Nonnull outputItems[],
      NSUInteger outputItemsCount) {
    NSUInteger count = 0;
    NSUInteger currentValuesIndex = 0;
    NSUInteger sourceIndex = state->extra[kSourceIndexKey];

    while (sourceIndex < state->extra[kSourceCountKey] && count < outputItemsCount) {
      // Save the result of the mapping in case the buffer can't hold all the values.
      if (!currentValues) {
        currentValues = block(sourceItems[sourceIndex]);
      }

      // Extract the set of values and add them to the output.
      for (id value in currentValues) {
        // Move to the item at the subindex.
        ++currentValuesIndex;
        if (currentValuesIndex <= state->extra[kSourceCurrentValuesKey]) {
          continue;
        }

        // Write data to output.
        outputItems[count] = value;
        ++count;

        state->extra[kSourceCurrentValuesKey] += 1;

        // Out of buffer space, stop enumeration and wait for the next call.
        if (count == outputItemsCount) {
          break;
        }
      }

      // Finished with the current \c NSFastEnumeration.
      if (count < outputItemsCount) {
        sourceIndex += 1;

        currentValues = nil;
        currentValuesIndex = 0;
        state->extra[kSourceCurrentValuesKey] = 0;
      }
    }

    state->extra[kSourceIndexKey] = sourceIndex;

    return count;
  };

  return [[LTFastEnumerator alloc] initWithSource:self operation:flatMap];
}

- (LTFastEnumerator *)flatten {
  return [self flatMap:^id<NSFastEnumeration>(id<NSFastEnumeration> value) {
    return value;
  }];
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  // The enumerator is stateless.
  return self;
}

@end

#pragma mark -
#pragma mark Extensions
#pragma mark -

@implementation NSArray (LTFastEnumerator)

- (LTFastEnumerator *)lt_enumerator {
  return [[LTFastEnumerator alloc] initWithSource:self];
}

@end

@implementation NSOrderedSet (LTFastEnumerator)

- (LTFastEnumerator *)lt_enumerator {
  return [[LTFastEnumerator alloc] initWithSource:self];
}

@end

NS_ASSUME_NONNULL_END
