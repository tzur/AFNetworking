// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "LTValueObject.h"

#import "LTHashExtensions.h"

NS_ASSUME_NONNULL_BEGIN

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

    // The limitation for ivar backed properties also prevents an endless recursion when objects
    // conform to NSObject, as the NSObject protocol contains hash and description as properties
    // without backing ivars, and accessing them calls the respective method on the receiver.
    if (attributes->ivar) {
      [propertyKeys addObject:propertyName];
    }
  }

  return propertyKeys;
}

NSString *LTValueObjectDescription(NSObject *object) {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p", object.class,
                                  object];

  for (NSString *key in LTPropertyKeys(object.class)) {
    [description appendFormat:@", %@: %@", key, [object valueForKey:key]];
  }

  [description appendString:@">"];
  return [description copy];
}

BOOL LTValueObjectIsEqual(NSObject *first, NSObject *second) {
  if (first == second) {
    return YES;
  }
  if (![second isKindOfClass:first.class]) {
    return NO;
  }

  for (NSString *key in LTPropertyKeys(first.class)) {
    id firstValue = [first valueForKey:key];
    id secondValue = [second valueForKey:key];

    if (firstValue != secondValue && ![firstValue isEqual:secondValue]) {
      return NO;
    }
  }

  return YES;
}

NSUInteger LTValueObjectHash(NSObject *object) {
  size_t seed = 0;

  for (NSString *key in LTPropertyKeys(object.class)) {
    lt::hash_combine(seed, [[object valueForKey:key] hash]);
  }

  return seed;
}

@implementation LTValueObject

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return LTValueObjectDescription(self);
}

- (BOOL)isEqual:(LTValueObject *)object {
  return LTValueObjectIsEqual(self, object);
}

- (NSUInteger)hash {
  return LTValueObjectHash(self);
}

@end

NS_ASSUME_NONNULL_END
