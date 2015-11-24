// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSBundle+Path.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSBundle (Path)

+ (nullable NSString *)lt_pathForResource:(NSString *)name nearClass:(Class)classObject {
  NSBundle *bundle = [self bundleForClass:classObject];
  return [bundle lt_pathForResource:name];
}

- (nullable NSString *)lt_pathForResource:(NSString *)name {
  NSString *resource = [name stringByDeletingPathExtension];
  NSString *type = name.pathExtension;
  return [self pathForResource:resource ofType:type];
}

@end

NS_ASSUME_NONNULL_END
