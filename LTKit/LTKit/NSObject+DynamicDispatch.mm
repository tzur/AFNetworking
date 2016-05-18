// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSObject+DynamicDispatch.h"

#import <mutex>

#import "LTHashExtensions.h"

NS_ASSUME_NONNULL_BEGIN

typedef std::pair<Class, SEL> LTMethodSignatureCacheEntry;

/// Holds a cache that maps <tt>{Class, SEL}</tt> to \c NSMethodSignature traits, such as if the
/// method returns a void value or not.
@interface LTMethodSignatureCache : NSObject {
  /// Mutex that protects the cache.
  std::mutex _mutex;

  /// Cache of method signatures identified by class and selector.
  std::unordered_map<LTMethodSignatureCacheEntry, BOOL,
      lt::hash<LTMethodSignatureCacheEntry>> _cache;
}

/// \c YES if the \c selector defined on the the given \c classObject returns void. If the method
/// signature of the <tt>{classObject, selector}</tt> is already cached, the result will be
/// immediately returned, otherwise it will be populated, added to the cache and then returned. If
/// the \c selector is not registered to \c classObject, an exception will be raised.
///
/// @note this method is thread safe.
- (BOOL)isVoidMethodOfClass:(Class)classObject selector:(SEL)selector;

@end

@implementation LTMethodSignatureCache

- (BOOL)isVoidMethodOfClass:(Class)classObject selector:(SEL)selector {
  std::lock_guard<std::mutex> lock(_mutex);

  LTMethodSignatureCacheEntry entry = {classObject, selector};

  const auto it = _cache.find(entry);
  if (it != _cache.cend()) {
    return it->second;
  }

  NSMethodSignature * _Nullable signature = [classObject
                                             instanceMethodSignatureForSelector:selector];
  LTParameterAssert(signature, @"Class %@ doesn't have an instance method signature of %@",
                    classObject, NSStringFromSelector(selector));

  BOOL isVoidMethod = !strcmp(signature.methodReturnType, "v");
  _cache[entry] = isVoidMethod;

  return isVoidMethod;
}

@end

@implementation NSObject (DynamicDispatch)

+ (LTMethodSignatureCache *)lt_methodSignatureCache {
  static LTMethodSignatureCache *cache;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cache = [[LTMethodSignatureCache alloc] init];
  });

  return cache;
}

- (nullable id)lt_dispatchSelector:(SEL)selector {
  if (![self respondsToSelector:selector]) {
    return nil;
  }

  IMP imp = [self methodForSelector:selector];
  if ([self lt_isVoidMethod:selector]) {
    void (*method)(id, SEL) = (void (*)(id, SEL))imp;
    method(self, selector);
    return nil;
  } else {
    id (*method)(id, SEL) = (id (*)(id, SEL))imp;
    return method(self, selector);
  }
}

- (nullable id)lt_dispatchSelector:(SEL)selector withObject:(id)object {
  if (![self respondsToSelector:selector]) {
    return nil;
  }

  IMP imp = [self methodForSelector:selector];
  if ([self lt_isVoidMethod:selector]) {
    void (*method)(id, SEL, id) = (void (*)(id, SEL, id))imp;
    method(self, selector, object);
    return nil;
  } else {
    id (*method)(id, SEL, id) = (id (*)(id, SEL, id))imp;
    return method(self, selector, object);
  }
}

- (nullable id)lt_dispatchSelector:(SEL)selector withObject:(id)object
                        withObject:(id)anotherObject {
  if (![self respondsToSelector:selector]) {
    return nil;
  }

  IMP imp = [self methodForSelector:selector];
  if ([self lt_isVoidMethod:selector]) {
    void (*method)(id, SEL, id, id) = (void (*)(id, SEL, id, id))imp;
    method(self, selector, object, anotherObject);
    return nil;
  } else {
    id (*method)(id, SEL, id, id) = (id (*)(id, SEL, id, id))imp;
    return method(self, selector, object, anotherObject);
  }
}

- (BOOL)lt_isVoidMethod:(SEL)selector {
  return [[[self class] lt_methodSignatureCache] isVoidMethodOfClass:[self class]
                                                            selector:selector];
}

@end

NS_ASSUME_NONNULL_END
