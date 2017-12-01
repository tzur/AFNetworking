// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LTUTICache.h"

#import <MobileCoreServices/MobileCoreServices.h>

NS_ASSUME_NONNULL_BEGIN

@implementation LTMobileCoreServices

- (BOOL)isUTI:(NSString *)uti conformsTo:(NSString *)conformsToUTI {
  return UTTypeConformsTo((__bridge CFStringRef)uti, (__bridge CFStringRef)conformsToUTI);
}

- (NSString *)preferredUTIForFileExtension:(NSString *)fileExt {
  return nn((__bridge_transfer NSString * _Nullable)UTTypeCreatePreferredIdentifierForTag(
      kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExt, NULL));
}

- (NSString *)preferredUTIForMIMEType:(NSString *)mimeType {
  return nn((__bridge_transfer NSString * _Nullable)UTTypeCreatePreferredIdentifierForTag(
      kUTTagClassMIMEType, (__bridge CFStringRef)mimeType, NULL));
}

- (nullable NSString *)preferredFileExtensionForUTI:(NSString *)uti {
  return (__bridge_transfer NSString * _Nullable)UTTypeCopyPreferredTagWithClass(
      (__bridge CFStringRef)uti, kUTTagClassFilenameExtension);
}

- (nullable NSString *)preferredMIMETypeForUTI:(NSString *)uti {
  return (__bridge_transfer NSString * _Nullable)UTTypeCopyPreferredTagWithClass(
      (__bridge CFStringRef)uti, kUTTagClassMIMEType);
}

@end

/// Caches the results of block execution. Each block execution is accompanied with a key which
/// differentiates between different block executions. For best results key must be a mapping
/// function of block's arguments, which affect the block's return value.
///
/// @important the block must not hold any internal state i.e. block must be time invariant,
/// otherwise it causes unpredictable behaviour.
///
/// @example Function `func` has the prototype NSNumber *func(NSNumber *num, NSString *str).
/// To cache the results of the `func` method use the following approach:
/// @code
/// return [blockCache cacheResultOfBlock:^NSNumber * _Nullable {
///   return func(num, str);
/// } forKey:@[num, str]];
/// @endcode
///
/// @important Always use the same block for the same instance. Mixing methods can lead to wrong
/// return values.
@interface LTBlockCache<ObjectType> : NSObject

/// Calls the given \c block and caches the result. Subsequent calls to this method with the same
/// \c key and \c namespace will return the result of the original \c block call.
///
/// If the block returns \c nil, it is cached as well.
///
/// @important the \c block must be time invariant i.e \c block must not hold any internal state.
- (nullable ObjectType)cacheResultOfBlock:(NS_NOESCAPE ObjectType _Nullable(^)())block
                                   forKey:(id<NSCopying>)key;

/// In-memory cache of the block's execution results. Maps keys to return value of the block.
@property (readonly, nonatomic) NSMutableDictionary<id, ObjectType> *cache;

@end

@implementation LTBlockCache

- (instancetype)init {
  if (self = [super init]) {
    _cache = [NSMutableDictionary dictionary];
  }
  return self;
}

- (nullable id)cacheResultOfBlock:(NS_NOESCAPE id _Nullable(^)())block forKey:(id<NSCopying>)key {
  @synchronized(self) {
    id _Nullable cachedResult = self.cache[key];
    if (cachedResult) {
      return (cachedResult == [NSNull null]) ? nil : cachedResult;
    }

    id result = block();
    self.cache[key] = result ?: [NSNull null];
    return result;
  }
}

@end

@interface LTUTICache ()

/// Underlying API whose method calls are cached.
@property (readonly, nonatomic) id<LTMobileCoreServices> mobileCoreServices;

/// Caches for methods in \c mobileCoreServices. Maps selector strings to the cache of the
/// selectors.
@property (readonly, nonatomic) NSDictionary<NSString *, LTBlockCache *> *caches;

@end

@implementation LTUTICache

- (instancetype)initWithMobileCoreServices:(id<LTMobileCoreServices>)mobileCoreServices {
  if (self = [super init]) {
    _mobileCoreServices = mobileCoreServices;
    _caches = @{
      NSStringFromSelector(@selector(isUTI:conformsTo:)): [[LTBlockCache alloc] init],
      NSStringFromSelector(@selector(preferredUTIForFileExtension:)): [[LTBlockCache alloc] init],
      NSStringFromSelector(@selector(preferredUTIForMIMEType:)): [[LTBlockCache alloc] init],
      NSStringFromSelector(@selector(preferredFileExtensionForUTI:)): [[LTBlockCache alloc] init],
      NSStringFromSelector(@selector(preferredMIMETypeForUTI:)): [[LTBlockCache alloc] init]
    };
  }
  return self;
}

+ (LTUTICache *)sharedCache {
  static auto singleton =
      [[LTUTICache alloc] initWithMobileCoreServices:[[LTMobileCoreServices alloc] init]];
  return singleton;
}

- (BOOL)isUTI:(NSString *)uti conformsTo:(NSString *)conformsToUTI {
  auto key = @[[uti lowercaseString], [conformsToUTI lowercaseString]];
  return [[nn(self.caches[NSStringFromSelector(_cmd)]) cacheResultOfBlock:^NSNumber * _Nullable {
    return @([self.mobileCoreServices isUTI:uti conformsTo:conformsToUTI]);
  } forKey:key] boolValue];
}

- (NSString *)preferredUTIForFileExtension:(NSString *)fileExt {
  return nn([nn(self.caches[NSStringFromSelector(_cmd)]) cacheResultOfBlock:^NSString * _Nullable {
    return [self.mobileCoreServices preferredUTIForFileExtension:fileExt];
  } forKey:[fileExt lowercaseString]]);
}

- (NSString *)preferredUTIForMIMEType:(NSString *)mimeType {
  return nn([nn(self.caches[NSStringFromSelector(_cmd)]) cacheResultOfBlock:^NSString * _Nullable {
    return [self.mobileCoreServices preferredUTIForMIMEType:mimeType];
  } forKey:[mimeType lowercaseString]]);
}

- (nullable NSString *)preferredFileExtensionForUTI:(NSString *)uti {
  return [nn(self.caches[NSStringFromSelector(_cmd)]) cacheResultOfBlock:^NSString * _Nullable {
    return [self.mobileCoreServices preferredFileExtensionForUTI:uti];
  } forKey:[uti lowercaseString]];
}

- (nullable NSString *)preferredMIMETypeForUTI:(NSString *)uti {
  return [nn(self.caches[NSStringFromSelector(_cmd)]) cacheResultOfBlock:^NSString * _Nullable {
    return [self.mobileCoreServices preferredMIMETypeForUTI:uti];
  } forKey:[uti lowercaseString]];
}

@end

NS_ASSUME_NONNULL_END
