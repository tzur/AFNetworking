// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "LTValueObject.h"

#import "LTHashExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTValueObject

static NSArray<NSString *> *LTPropertyKeys(Class classObject) {
  unsigned int count = 0;
  objc_property_t *properties = class_copyPropertyList(classObject, &count);
  if (!count) {
    return @[];
  }
  
  @onExit {
    free(properties);
  };
  
  NSMutableArray<NSString *> *propertyKeys = [NSMutableArray arrayWithCapacity:count];
  for (unsigned i = 0; i < count; ++i) {
    NSString *propertyName = @(property_getName(properties[i]));
    LTAssert(propertyName, @"Failed fetching property name");

    ext_propertyAttributes *attributes = ext_copyPropertyAttributes(properties[i]);
    @onExit {
      free(attributes);
    };
    
    LTAssert(attributes, @"Failed fetching property attributes for property: %@ from class: %@",
             propertyName, NSStringFromClass(classObject));
    LTAssert(!attributes->weak, @"Weak properties are prohibited by this, property: %@ from class: "
             "%@ is weak", propertyName, NSStringFromClass(classObject));
    
    [propertyKeys addObject:propertyName];
  }
  
  return propertyKeys;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p", self.class, self];

  for (NSString *key in LTPropertyKeys(self.class)) {
    [description appendFormat:@", %@: %@", key, [self valueForKey:key]];
  }

  [description appendString:@">"];
  return [description copy];
}

- (BOOL)isEqual:(LTValueObject *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  for (NSString *key in LTPropertyKeys(self.class)) {
    id selfValue = [self valueForKey:key];
    id objectValue = [object valueForKey:key];

    if (selfValue != objectValue && ![selfValue isEqual:objectValue]) {
      return NO;
    }
  }
  
  return YES;
}

- (NSUInteger)hash {
  size_t seed = 0;

  for (NSString *key in LTPropertyKeys(self.class)) {
    lt::hash_combine(seed, [[self valueForKey:key] hash]);
  }

  return seed;
}

@end

NS_ASSUME_NONNULL_END
