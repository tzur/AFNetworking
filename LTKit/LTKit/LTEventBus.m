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

@end

@implementation LTEventBus

- (instancetype)init {
  if (self = [super init]) {
    _classObservers = [NSMutableDictionary dictionary];
    _protocolObservers = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)addObserver:(id)target selector:(SEL)selector forClass:(Class)objClass {
  LTParameterAssert(objClass, @"Attempting to observe nil class. Use NSObject to observe all");
  LTParameterAssert(object_isClass(objClass), @"Attempting to observe instance, not class");
  [self verifySelector:selector forTarget:target];

  LTEventObserver *observer = [[LTEventObserver alloc] initWithTarget:target selector:selector];

  [self addObserver:observer toClass:objClass];
}

- (void)addObserver:(id)target selector:(SEL)selector forProtocol:(Protocol *)protocol {
  LTParameterAssert(protocol, @"Attempting to observe nil protocol.");
  [self verifySelector:selector forTarget:target];
  
  LTEventObserver *observer = [[LTEventObserver alloc] initWithTarget:target selector:selector];
  
  [self addObserver:observer toProtocol:protocol];
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

- (void)addObserver:(LTEventObserver *)observer toClass:(Class)objClass {
  NSMutableArray *classObservers = self.classObservers[objClass];
  if (!classObservers) {
    classObservers = [NSMutableArray array];
    // Class objects conform to NSCopying even though they don't declare it - see for more info:
    // http://stackoverflow.com/a/769627/1074055
    self.classObservers[(id<NSCopying>)objClass] = classObservers;
  }
  [classObservers addObject:observer];
}

- (void)addObserver:(LTEventObserver *)observer toProtocol:(Protocol *)protocol {
  NSMutableArray *protocolObservers = self.protocolObservers[NSStringFromProtocol(protocol)];
  if (!protocolObservers) {
    protocolObservers = [NSMutableArray array];
    self.protocolObservers[NSStringFromProtocol(protocol)] = protocolObservers;
  }
  [protocolObservers addObject:observer];
}

- (void)removeObserver:(id)target forClass:(Class)objClass {
  for (Class observedClass in self.classObservers) {
    if (objClass && ![observedClass isSubclassOfClass:objClass]) {
      continue;
    }
    [self removeObserver:target forKey:observedClass from:self.classObservers];
  }
}

- (void)removeObserver:(id)target forProtocol:(nonnull Protocol *)protocol {
  for (NSString *observedProtocol in self.protocolObservers) {
    if (protocol && !protocol_conformsToProtocol(NSProtocolFromString(observedProtocol),
                                                 protocol)) {
      continue;
    }
    [self removeObserver:target forKey:observedProtocol from:self.protocolObservers];
  }
}

- (void)removeObserver:(id)target forKey:(id)key from:(NSMutableDictionary *)dictionary {
  NSMutableArray *toDiscard = [NSMutableArray array];
  for (LTEventObserver *observer in dictionary[key]) {
    if (target == observer.target) {
      [toDiscard addObject:observer];
    }
  }
  [dictionary[key] removeObjectsInArray:toDiscard];
}

- (void)post:(id)object {
  LTParameterAssert(object, @"Attempting to post a nil object");
  for (Class observedClass in self.classObservers) {
    if (![object isKindOfClass:observedClass]) {
      continue;
    }
    [self post:object toObservers:self.classObservers[observedClass]];
  }
  for (NSString *observedProtocol in self.protocolObservers) {
    if (![object conformsToProtocol:NSProtocolFromString(observedProtocol)]) {
      continue;
    }
    [self post:object toObservers:self.protocolObservers[observedProtocol]];
  }
}

- (void)post:(id)object toObservers:(NSMutableArray *)observers {
  NSMutableArray *toDiscard = [NSMutableArray array];
  NSMutableArray *toNotify = [NSMutableArray array];
  for (LTEventObserver *observer in observers) {
    if (observer.target) {
      [toNotify addObject:observer];
    } else {
      [toDiscard addObject:observer];
    }
  }
  for (LTEventObserver *observer in toNotify) {
    [self post:object toObserver:observer];
  }
  [observers removeObjectsInArray:toDiscard];
}

- (void)post:(id)object toObserver:(LTEventObserver *)observer {
  id strongTarget = observer.target;
  if (!strongTarget) {
    // Observers hold a weak reference to their target, and while we did check that it's not nil
    // earlier, it's still possible it will become nil, so we perform this final check, to make
    // sure we don't send invocation to a stale pointer.
    // (If target did dealloc, the observer will be discarded the next time post:info: is called.)
    return;
  }

  // The selector is guaranteed to exist (and be valid) because we already tested it above in
  // \c verifySelector:forTarget:.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  [strongTarget performSelector:observer.selector withObject:object];
#pragma clang diagnostic pop
}

@end

NS_ASSUME_NONNULL_END
