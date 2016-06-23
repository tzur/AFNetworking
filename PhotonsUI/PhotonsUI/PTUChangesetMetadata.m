// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUChangesetMetadata.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTUChangesetMetadata

- (instancetype)initWithTitle:(nullable NSString *)title
                sectionTitles:(NSDictionary<NSNumber *, NSString *> *)sectionTitles {
  if (self = [super init]) {
    _title = title;
    _sectionTitles = sectionTitles;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTUChangesetMetadata *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self compare:self.title with:object.title] &&
      [self.sectionTitles isEqual:object.sectionTitles];
}

- (BOOL)compare:(nullable id)first with:(nullable id)second {
  return first == second || [first isEqual:second];
}

- (NSUInteger)hash {
  return self.title.hash ^ self.sectionTitles.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, title: %@, sectionTitles: %@>", self.class, self,
          self.title, self.sectionTitles];
}

@end

NS_ASSUME_NONNULL_END
