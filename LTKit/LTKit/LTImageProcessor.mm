// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

@implementation LTImageProcessor

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)preprocess {
}

- (void)process {
  LTMethodNotImplemented();
}

#pragma mark -
#pragma mark Load / save
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  return nil;
}

- (void)setInputModel:(NSDictionary *)model {
  // For an undefined input model, exit gracefully.
  if (![[self class] inputModelPropertyKeys]) {
    return;
  }

  LTParameterAssert([[NSSet setWithArray:model.allKeys]
                     isEqualToSet:[[self class] inputModelPropertyKeys]],
                    @"Given model properties doesn't include the same keys as need to be saved "
                    "(%@ vs. %@)",
                    [NSSet setWithArray:model.allKeys], [[self class] inputModelPropertyKeys]);

  for (NSString *key in model) {
    // TODO: (yaron) Since setValue:forKeyPath: doesn't have type-safety, add type validation here.
    [self setValue:model[key] forKeyPath:key];
  }
}

- (NSDictionary *)inputModel {
  NSMutableDictionary *model = [NSMutableDictionary dictionary];

  for (NSString *key in [[self class] inputModelPropertyKeys]) {
    id value = [self valueForKeyPath:key] ?: [NSNull null];
    model[key] = value;
  }

  return [model copy];
}

- (NSDictionary *)defaultInputModel {
  NSMutableDictionary *defaultModel = [NSMutableDictionary dictionary];

  for (NSString *key in [[self class] inputModelPropertyKeys]) {
    defaultModel[key] = [self valueForKey:[self defaultKeyForKey:key]];
  }

  return [defaultModel copy];
}

- (id)defaultValueForKey:(NSString *)key {
  if (![[[self class] inputModelPropertyKeys] containsObject:key]) {
    return nil;
  }
  return [self valueForKey:[self defaultKeyForKey:key]];
}

- (void)resetInputModel {
  [self resetInputModelExceptKeys:nil];
}

- (void)resetInputModelExceptKeys:(NSSet *)keys {
  for (NSString *key in [[self class] inputModelPropertyKeys]) {
    if ([keys containsObject:key]) {
      continue;
    }

    NSString *defaultKey = [self defaultKeyForKey:key];
    [self setValue:[self valueForKey:defaultKey] forKey:key];
  }
}

- (void)resetValueForKey:(NSString *)key {
  id defaultValue = [self defaultValueForKey:key];
  [self setValue:defaultValue forKey:key];
}

- (NSString *)defaultKeyForKey:(NSString *)key {
  NSString *initial = [[key substringToIndex:1] uppercaseString];
  NSString *rest = [key substringFromIndex:1];
  NSString *defaultKey = [@[@"default", initial, rest] componentsJoinedByString:@""];

  LTAssert([self respondsToSelector:NSSelectorFromString(defaultKey)],
           @"Tried to fetch a default value for key %@, but the default key %@ doesn't exist",
           key, defaultKey);

  return defaultKey;
}

+ (BOOL)isPassthroughForDefaultInputModel {
  return YES;
}

#pragma mark -
#pragma mark LTJSONSerializing
#pragma mark -

+ (NSSet *)serializableKeyPaths {
  return [[self class] inputModelPropertyKeys];
}

@end
