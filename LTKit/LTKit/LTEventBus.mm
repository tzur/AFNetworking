// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "LTEventBus.h"

NS_ASSUME_NONNULL_BEGIN

/// Represents a single observer (i.e. target).
@interface LTEventObserver : NSObject

/// Target to send \c selector to.
@property (weak, readonly, nonatomic) id target;

/// Selector to send to \c target.
@property (readonly, nonatomic) SEL selector;

@end

@implementation LTEventObserver

/// Initializes this observer with the given \c target and \c selector.
- (instancetype)initWithTarget:(id)target selector:(SEL)selector {
  if (self = [super init]) {
    _target = target;
    _selector = selector;
  }
  return self;
}

@end

@interface LTEventBus ()

/// Dictionary mapping event class to an array of its observers.
@property (readonly, nonatomic) NSMutableDictionary *classObservers;

/// Dictionary mapping event protocol to an array of its observers.
@property (readonly, nonatomic) NSMutableDictionary *protocolObservers;

/// Dispatch queue for thread safe reading and writing to the observer arrays.
@property (readonly, nonatomic) dispatch_queue_t readWriteQueue;

@end

@implementation LTEventBus

- (instancetype)init {
  if (self = [super init]) {
    _classObservers = [NSMutableDictionary dictionary];
    _protocolObservers = [NSMutableDictionary dictionary];
    _readWriteQueue = dispatch_queue_create("com.lightricks.LTKit.EventBus",
                                            DISPATCH_QUEUE_CONCURRENT);
  }
  return self;
}

- (void)addObserver:(id)target selector:(SEL)selector forClass:(Class)objClass {
  [self addObserver:target selector:selector withKey:objClass toDictionary:self.classObservers];
}

- (void)addObserver:(id)target selector:(SEL)selector forProtocol:(Protocol *)protocol {
  [self addObserver:target selector:selector withKey:NSStringFromProtocol(protocol)
       toDictionary:self.protocolObservers];
}

- (void)addObserver:(id)target selector:(SEL)selector withKey:(id)key
       toDictionary:(NSMutableDictionary *)dictionary {
  [self verifySelector:selector forTarget:target];

  LTEventObserver *observer = [[LTEventObserver alloc] initWithTarget:target selector:selector];

  dispatch_barrier_sync(self.readWriteQueue, ^{
    [self addObserver:observer withKey:key toDictionary:dictionary];
  });
}

- (void)verifySelector:(SEL)selector forTarget:(id)target {
  LTParameterAssert([target respondsToSelector:selector],
      @"Selector %@ not available on target", NSStringFromSelector(selector));
  NSMethodSignature *signature = [target methodSignatureForSelector:selector];
  NSString *selectorString = NSStringFromSelector(selector);

  const char *typeString;
  switch ([signature numberOfArguments]) {
    case 3:
      typeString = [signature getArgumentTypeAtIndex:2];
      LTParameterAssert(strcmp(typeString, @encode(id)) == 0,
          @"Selector %@ must accept an object for first parameter, but instead accepts type %s",
          selectorString, typeString);
      break;
    default:
      LTParameterAssert(NO, @"Selector %@ must accept exactly one argument", selectorString);
      break;
  }
  LTParameterAssert([signature methodReturnLength] == 0,
      @"Selector %@ must return void", selectorString);
}

- (void)addObserver:(LTEventObserver *)observer withKey:(id)key
       toDictionary:(NSMutableDictionary *)dictionary {
  NSMutableArray * _Nullable observers = dictionary[key];
  if (observers) {
    [observers addObject:observer];
  } else {
    dictionary[key] = [@[observer] mutableCopy];
  }
}

- (void)removeObserver:(id)target forClass:(Class)objClass {
  dispatch_barrier_sync(self.readWriteQueue, ^{
    for (Class observedClass in self.classObservers) {
      if ([observedClass isSubclassOfClass:objClass]) {
        [self removeObserver:target withKey:observedClass fromDictionary:self.classObservers];
      }
    }
  });
}

- (void)removeObserver:(id)target forProtocol:(Protocol *)protocol {
  dispatch_barrier_sync(self.readWriteQueue, ^{
    for (NSString *observedProtocol in self.protocolObservers) {
      if (protocol_conformsToProtocol(NSProtocolFromString(observedProtocol), protocol)) {
        [self removeObserver:target withKey:observedProtocol fromDictionary:self.protocolObservers];
      }
    }
  });
}

- (void)removeObserver:(id)target withKey:(id)key fromDictionary:(NSDictionary *)dictionary {
    NSMutableArray *toRemove = [NSMutableArray array];
    for (LTEventObserver *observer in dictionary[key]) {
      id _Nullable observerTarget = observer.target;
      if (observerTarget && target == nn(observer.target)) {
        [toRemove addObject:observer];
      }
    }
    [dictionary[key] removeObjectsInArray:toRemove];
}

- (void)post:(id)object {
  NSMutableArray<LTEventObserver *> *toNotify = [NSMutableArray array];

  dispatch_sync(self.readWriteQueue, ^{
    [self.classObservers enumerateKeysAndObjectsUsingBlock:^(Class observedClass,
                                                             NSArray *observers, BOOL *) {
      if ([object isKindOfClass:observedClass]) {
        [toNotify addObjectsFromArray:observers];
      }
    }];

    [self.protocolObservers enumerateKeysAndObjectsUsingBlock:^(NSString *observedProtocol,
                                                                NSArray *observers, BOOL *) {
      if ([object conformsToProtocol:NSProtocolFromString(observedProtocol)]) {
        [toNotify addObjectsFromArray:observers];
      }
    }];
  });

  [self post:object toObservers:toNotify];
}

- (void)post:(id)object toObservers:(NSArray<LTEventObserver *> *)observers {
  for (LTEventObserver *observer in observers) {
    id strongTarget = observer.target;

    // The selector is guaranteed to exist (and be valid) because we already tested it above in
    // \c verifySelector:forTarget:.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [strongTarget performSelector:observer.selector withObject:object];
#pragma clang diagnostic pop
  }
}

@end

NS_ASSUME_NONNULL_END
