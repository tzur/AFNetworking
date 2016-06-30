// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPResponse.h"

#import "FBRCompare.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBRHTTPResponse

- (instancetype)initWithMetadata:(NSHTTPURLResponse *)metadata content:(nullable NSData *)content {
  if (self = [super init]) {
    _metadata = metadata;
    _content = content;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(FBRHTTPResponse *)object {
  if (object == self) {
    return YES;
  } else if (![object isKindOfClass:[self class]]) {
    return NO;
  }

  return FBRCompare(self.metadata, object.metadata) && FBRCompare(self.content, object.content);
}

- (NSUInteger)hash {
  return self.metadata.hash ^ self.content.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, metadata: %@, content-length: %lu", [self class],
          self, self.metadata, (unsigned long)self.content.length];
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

@end

NS_ASSUME_NONNULL_END
