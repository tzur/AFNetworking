// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

@implementation LTImageProcessor

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)process {
  LTMethodNotImplemented();
}

#pragma mark -
#pragma mark Load / save
#pragma mark -

- (void)setInputModel:(NSDictionary *)model {
  // For an undefined input model, exit gracefully.
  if (![[self class] inputModelProperties]) {
    return;
  }

  LTParameterAssert([[NSSet setWithArray:model.allKeys]
                     isEqualToSet:[[self class] inputModelProperties]],
                    @"Given model properties doesn't include the same keys as need to be saved "
                    "(%@ vs. %@)",
                    [NSSet setWithArray:model.allKeys], [[self class] inputModelProperties]);

  for (NSString *key in model) {
    // TODO: (yaron) Since setValue:forKeyPath: doesn't have type-safety, add type validation here.

    Class objectClass = [self classForKey:key];
    if ([objectClass conformsToProtocol:@protocol(LTEnum)] &&
        [model[key] isKindOfClass:[NSString class]]) {
      id<LTEnum> enumObject = [[objectClass alloc] initWithName:model[key]];
      [self setValue:enumObject forKeyPath:key];
    } else {
      [self setValue:model[key] forKeyPath:key];
    }
  }
}

- (NSDictionary *)inputModel {
  NSMutableDictionary *model = [NSMutableDictionary dictionary];

  for (NSString *key in [[self class] inputModelProperties]) {
    id value = [self valueForKeyPath:key] ?: [NSNull null];

    // Convert LTEnum to its string representation.
    if ([value conformsToProtocol:@protocol(LTEnum)]) {
      model[key] = ((id<LTEnum>)value).name;
    } else {
      model[key] = value;
    }
  }

  return [model copy];
}

- (Class)classForKey:(NSString *)key {
  ext_propertyAttributes *attributes = [self propertyAttributesForKey:key];
  @onExit {
    free(attributes);
  };

  return attributes->objectClass;
}

+ (NSSet *)inputModelProperties {
  return nil;
}

#pragma mark -
#pragma mark Union handling
#pragma mark -

+ (NSSet *)allowedUnionTypes {
  static NSSet *allowedTypes;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    allowedTypes = [NSSet setWithArray:@[
      @(@encode(GLKVector2)), @(@encode(GLKVector3)), @(@encode(GLKVector4)),
      @(@encode(GLKMatrix2)), @(@encode(GLKMatrix3)), @(@encode(GLKMatrix4))
    ]];
  });

  return allowedTypes;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
  ext_propertyAttributes *attributes = [self propertyAttributesForKey:key];
  @onExit {
    free(attributes);
  };

  if (![[[self class] allowedUnionTypes] containsObject:@(attributes->type)]) {
    [super setValue:value forUndefinedKey:key];
  }

  [self setValue:value forProperty:attributes];
}

- (void)setValue:(id)value forProperty:(ext_propertyAttributes *)attributes {
  LTAssert([value isKindOfClass:[NSValue class]], @"This method supports only NSValue as an "
           "argument to set to a property. To set objects or other primitives, use the canonical "
           "setValue:forKey:");

  NSMethodSignature *signature = [self signatureForSelector:attributes->setter];

  // Arguments should contain self, _cmd and the value to set.
  LTAssert(signature.numberOfArguments == 3, @"Property setter must have a single input argument");

  NSUInteger size;
  NSGetSizeAndAlignment([signature getArgumentTypeAtIndex:2], &size, NULL);
  std::unique_ptr<char[]> argument(new char[size]);
  [value getValue:argument.get()];

  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  [invocation setArgument:argument.get() atIndex:2];
  [invocation setSelector:attributes->setter];
  [invocation invokeWithTarget:self];
}

- (id)valueForUndefinedKey:(NSString *)key {
  ext_propertyAttributes *attributes = [self propertyAttributesForKey:key];
  @onExit {
    free(attributes);
  };

  if (!attributes || ![[[self class] allowedUnionTypes] containsObject:@(attributes->type)]) {
    [super valueForUndefinedKey:key];
  }

  return [self valueForProperty:attributes];
}

- (NSValue *)valueForProperty:(ext_propertyAttributes *)attributes {
  LTAssert(attributes, @"Given property attributes cannot be NULL");

  NSMethodSignature *signature = [self signatureForSelector:attributes->getter];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  [invocation setSelector:attributes->getter];
  [invocation invokeWithTarget:self];

  std::unique_ptr<char[]> value(new char[signature.methodReturnLength]);
  [invocation getReturnValue:value.get()];

  // Return value with the original type and not the stripped one to preserve \c isEqualToValue:
  // to matching uniforms.
  return [NSValue valueWithBytes:value.get() objCType:attributes->type];
}

- (ext_propertyAttributes *)propertyAttributesForKey:(NSString *)key {
  const char *name = [key cStringUsingEncoding:NSUTF8StringEncoding];
  objc_property_t property = class_getProperty(self.class, name);
  if (!property) {
    return nil;
  }

  return ext_copyPropertyAttributes(property);
}

- (NSMethodSignature *)signatureForSelector:(SEL)selector {
  Method method = class_getInstanceMethod([self class], selector);
  struct objc_method_description *desc = method_getDescription(method);

  NSString *types = [self stripUnionFromTypeEncoding:@(desc->types)];
  const char *objcTypes = [types cStringUsingEncoding:NSUTF8StringEncoding];

  return [NSMethodSignature signatureWithObjCTypes:objcTypes];
}

- (NSString *)stripUnionFromTypeEncoding:(NSString *)encoding {
  NSMutableString *mutableEncoding = [encoding mutableCopy];

  NSRegularExpression *regex = [[self class] stripUnionRegex];
  [regex replaceMatchesInString:mutableEncoding options:0
                          range:NSMakeRange(0, encoding.length) withTemplate:@"$1"];

  return [mutableEncoding copy];
}

+ (NSRegularExpression *)stripUnionRegex {
  static NSRegularExpression *regex;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSError *error;
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\(.*?=(\\{.*?\\}).*?\\)"
                                                      options:0 error:&error];
    LTAssert(!error, @"Encountered error while creating regex: %@", error.description);
  });

  return regex;
}

@end
