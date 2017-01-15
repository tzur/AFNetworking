// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSValueTransformer+LTEngine.h"

#import <LTKit/LTPath.h>
#import <LTKit/UIColor+Utilities.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

NSString * const kLTClassValueTransformer = @"LTClassValueTransformer";
NSString * const kLTModelValueTransformer = @"LTModelValueTransformer";
NSString * const kLTColorValueTransformer = @"LTColorValueTransformer";
NSString * const kLTUUIDValueTransformer = @"LTUUIDValueTransformer";
NSString * const kLTUTCDateValueTransformer = @"LTStandardDateValueTransformer";
NSString * const kLTTimeZoneValueTransformer = @"LTTimeZoneValueTransformer";
NSString * const kLTLTPathValueTransformer = @"LTLTPathValueTransformer";
NSString * const kLTURLValueTransformer = @"LTURLValueTransformer";

NSString * const kLTModelValueTransformerClassKey = @"_class";
NSString * const kLTModelValueTransformerEnumNameKey = @"name";

@implementation NSValueTransformer (LTEngine)

#pragma mark -
#pragma mark Gloal transformers
#pragma mark -

+ (void)load {
  @autoreleasepool {
    [NSValueTransformer setValueTransformer:[self lt_classValueTransformer]
                                    forName:kLTClassValueTransformer];
    [NSValueTransformer setValueTransformer:[self lt_modelValueTransformer]
                                    forName:kLTModelValueTransformer];
    [NSValueTransformer setValueTransformer:[self lt_colorValueTransformer]
                                    forName:kLTColorValueTransformer];
    [NSValueTransformer setValueTransformer:[self lt_UUIDValueTransformer]
                                    forName:kLTUUIDValueTransformer];
    [NSValueTransformer setValueTransformer:[self lt_UTCDateFormatterValueTransformer]
                                    forName:kLTUTCDateValueTransformer];
    [NSValueTransformer setValueTransformer:[self lt_timeZoneValueTransformer]
                                    forName:kLTTimeZoneValueTransformer];
    [NSValueTransformer setValueTransformer:[self lt_ltPathValueTransformer]
                                    forName:kLTLTPathValueTransformer];
    [NSValueTransformer setValueTransformer:[self lt_ltURLValueTransformer]
                                    forName:kLTURLValueTransformer];
  }
}

+ (NSValueTransformer *)lt_classValueTransformer {
  return [MTLValueTransformer
      reversibleTransformerWithForwardBlock:^Class(NSString *className) {
        Class _Nullable classObject = NSClassFromString(className);
        LTParameterAssert(classObject, @"Got invalid class name: %@", className);
        return classObject;
      } reverseBlock:^NSString * _Nullable(Class classObject) {
        return NSStringFromClass(classObject);
      }];
}

+ (NSValueTransformer *)lt_modelValueTransformer {
  return [MTLValueTransformer
      reversibleTransformerWithForwardBlock:^id _Nullable(NSDictionary *value) {
    if (!value) {
      return nil;
    }

    if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
      return value;
    }

    LTParameterAssert([value isKindOfClass:[NSDictionary class]],
                      @"Expected a dictionary, got: %@", value.class);
    LTParameterAssert(value[kLTModelValueTransformerClassKey], @"Given dictionary doesn't define "
                      "model class key '%@', got: %@", kLTModelValueTransformerClassKey, value);

    Class _Nullable modelClass = NSClassFromString(value[kLTModelValueTransformerClassKey]);
    LTParameterAssert(modelClass, @"Given model class '%@' doesn't exist",
                      value[kLTModelValueTransformerClassKey]);

    if ([modelClass conformsToProtocol:@protocol(LTEnum)]) {
      LTParameterAssert(value[kLTModelValueTransformerEnumNameKey], @"Given dictionary doesn't "
                        "define enum name key '%@', got: %@", kLTModelValueTransformerEnumNameKey,
                        value);

      return [[self lt_enumNameTransformerForClass:modelClass]
              transformedValue:value[kLTModelValueTransformerEnumNameKey]];
    }

    LTParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)],
                      @"Given model class '%@' doesn't conform to MTLJSONSerializing", modelClass);
    LTParameterAssert([modelClass isSubclassOfClass:[MTLModel class]],
                      @"Given model class '%@' is not a subclass of MTLModel", modelClass);

    NSValueTransformer *transformer = [NSValueTransformer
                                       mtl_JSONDictionaryTransformerWithModelClass:modelClass];
    return [transformer transformedValue:value];
  } reverseBlock:^id _Nullable(MTLModel *model) {
    if (!model) {
      return nil;
    }

    if ([model isKindOfClass:[NSNumber class]] || [model isKindOfClass:[NSString class]]) {
      return model;
    }

    if ([model conformsToProtocol:@protocol(LTEnum)]) {
      NSValueTransformer *transformer = [self lt_enumNameTransformerForClass:model];
      return @{
        kLTModelValueTransformerClassKey: NSStringFromClass(model.class),
        kLTModelValueTransformerEnumNameKey: [transformer reverseTransformedValue:model]
      };
    }

    LTParameterAssert([model isKindOfClass:[MTLModel class]],
                      @"Expected a model, got: %@", model.class);
    LTParameterAssert([model conformsToProtocol:@protocol(MTLJSONSerializing)],
                      @"Expected a model that conforms to MTLJSONSerializing, got: %@",
                      model.class);

    NSValueTransformer *transformer = [NSValueTransformer
                                       mtl_JSONDictionaryTransformerWithModelClass:model.class];
    NSDictionary *value = [transformer reverseTransformedValue:model];
    return [value mtl_dictionaryByAddingEntriesFromDictionary:@{
      kLTModelValueTransformerClassKey: NSStringFromClass(model.class)
    }];
  }];
}

+ (NSValueTransformer *)lt_colorValueTransformer {
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:^UIColor *(NSString *string) {
    LTParameterAssert([string isKindOfClass:NSString.class],
                      @"Expected a NSString, got: %@", string.class);
    return [UIColor lt_colorWithHex:string];
  } reverseBlock:^NSString *(UIColor *color) {
    LTParameterAssert([color isKindOfClass:UIColor.class],
                      @"Expected a UIColor, got: %@", color.class);
    return [color lt_hexString];
  }];
}

+ (NSValueTransformer *)lt_UUIDValueTransformer {
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:^NSUUID *(NSString *string) {
    if (!string) {
      return nil;
    }
    LTParameterAssert([string isKindOfClass:NSString.class],
                      @"Expected a NSString, got: %@", string.class);
    NSUUID *result = [[NSUUID alloc] initWithUUIDString:string];
    LTParameterAssert(result, @"Given string %@ is not according to standard UUID format", string);
    return result;
  } reverseBlock:^NSString *(NSUUID *uuid) {
    if (!uuid) {
      return nil;
    }
    LTParameterAssert([uuid isKindOfClass:NSUUID.class],
                      @"Expected a NSUUID, got: %@", uuid.class);
    return [uuid UUIDString];
  }];
}

+ (NSValueTransformer *)lt_UTCDateFormatterValueTransformer {
  return [self lt_dateValueTransformerWithFormatter:[self lt_UTCDateFormatter]];
}

+ (NSValueTransformer *)lt_dateValueTransformerWithFormatter:(NSDateFormatter *)formatter {
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:^NSDate *(NSString *string) {
    LTParameterAssert([string isKindOfClass:NSString.class],
                      @"Expected a NSString, got: %@", string.class);
    NSDate *result = [formatter dateFromString:string];
    LTParameterAssert(result, @"Given string %@ is not according to expected format", string);
    return result;
  } reverseBlock:^NSString *(NSDate *date) {
    LTParameterAssert([date isKindOfClass:NSDate.class],
                      @"Expected a NSDate, got: %@", date.class);
    return [formatter stringFromDate:date];
  }];
}

+ (NSDateFormatter *)lt_UTCDateFormatter {
  static NSDateFormatter *dateFormatter;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
  });
  
  return dateFormatter;
}

+ (NSValueTransformer *)lt_timeZoneValueTransformer {
  return
      [MTLValueTransformer reversibleTransformerWithForwardBlock:^NSTimeZone *(NSString *string) {
    LTParameterAssert([string isKindOfClass:NSString.class],
                      @"Expected a NSString, got: %@", string.class);
    NSTimeZone *result = [NSTimeZone timeZoneWithName:string];
    LTParameterAssert(result, @"Given string %@ is not a known time zone name", string);
    return result;
  } reverseBlock:^NSString *(NSTimeZone *timezone) {
    LTParameterAssert([timezone isKindOfClass:NSTimeZone.class],
                      @"Expected a NSTimeZone, got: %@", timezone.class);
    return timezone.name;
  }];
}

+ (NSValueTransformer *)lt_ltPathValueTransformer {
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:^LTPath *(NSString *string) {
    LTParameterAssert([string isKindOfClass:NSString.class],
                      @"Expected a NSString, got: %@", string.class);
    LTPath * _Nullable result = [LTPath pathWithRelativeURL:[NSURL URLWithString:string]];
    LTParameterAssert(result, @"Given string %@ is not according to expected format", string);
    return result;
  } reverseBlock:^NSString *(LTPath *path) {
    LTParameterAssert([path isKindOfClass:LTPath.class],
                      @"Expected an LTPath, got: %@", path.class);
    return path.relativeURL.absoluteString;
  }];
}

+ (NSValueTransformer *)lt_ltURLValueTransformer {
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:
      ^NSURL * _Nullable (NSString *string) {
        LTParameterAssert([string isKindOfClass:NSString.class],
                          @"Expected a NSString, got: %@", string.class);
        NSString *escapedUrl = [string stringByAddingPercentEncodingWithAllowedCharacters:
                                [NSCharacterSet URLQueryAllowedCharacterSet]];
        return [NSURL URLWithString:escapedUrl];
  } reverseBlock:^NSString *(NSURL *url) {
    LTParameterAssert([url isKindOfClass:NSURL.class],
                      @"Expected a NSURL, got: %@", url.class);
    return url.absoluteString;
  }];
}

#pragma mark -
#pragma mark Transformer methods
#pragma mark -

+ (NSValueTransformer *)lt_JSONDictionaryTransformerWithValuesOfModelClass:(Class)modelClass {
  NSValueTransformer *dictionaryTransformer =
      [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:modelClass];
  return [self lt_JSONDictionaryTransformerWithTransformer:dictionaryTransformer];
}

+ (NSValueTransformer *)lt_JSONDictionaryTransformerWithTransformer:
    (NSValueTransformer *)transformer {
  return [MTLValueTransformer
          reversibleTransformerWithForwardBlock:^NSDictionary * _Nullable(NSDictionary *values) {
    if (!values) {
      return nil;
    }

    LTParameterAssert([values isKindOfClass:[NSDictionary class]],
                      @"Expected a dictionary, got: %@", values.class);

    NSMutableDictionary *transformedValues =
                [NSMutableDictionary dictionaryWithCapacity:values.count];
    [values enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL __unused *stop) {
      LTParameterAssert([key isKindOfClass:[NSString class]],
                        @"Expected key to be NSString, got: %@", key.class);

      id _Nullable transformedValue = [transformer transformedValue:value];
      LTParameterAssert(transformedValue, @"Transformation of key %@ with value %@ using "
                        "transformer %@ returned nil", key, value, transformer);
      transformedValues[key] = transformedValue;
    }];

    return [transformedValues copy];
  } reverseBlock:^NSDictionary *(NSDictionary *transformedValues) {
    if (!transformedValues) {
      return nil;
    }

    LTParameterAssert([transformedValues isKindOfClass:[NSDictionary class]],
                      @"Expected a dictionary, got: %@", transformedValues.class);

    NSMutableDictionary *values =
        [NSMutableDictionary dictionaryWithCapacity:transformedValues.count];
    [transformedValues enumerateKeysAndObjectsUsingBlock:^(NSString *key, id transformedValue,
                                                BOOL __unused *stop) {
      LTParameterAssert([key isKindOfClass:[NSString class]],
                        @"Expected key to be NSString, got: %@", key.class);

      id _Nullable value = [transformer reverseTransformedValue:transformedValue];
      LTParameterAssert(value, @"Reverse transformation of key %@ with value %@ using transformer "
                        "%@ returned nil", key, transformedValue, transformer);
      values[key] = value;
    }];

    return [values copy];
  }];
}

+ (NSValueTransformer *)lt_JSONArrayTransformerWithTransformer:(NSValueTransformer *)transformer {
  return [MTLValueTransformer
          reversibleTransformerWithForwardBlock:^NSArray * _Nullable(NSArray *values) {
    if (!values) {
      return nil;
    }

    LTParameterAssert([values isKindOfClass:[NSArray class]], @"Expected an array, got: %@",
                      values.class);

    NSMutableArray *transformedValues = [NSMutableArray arrayWithCapacity:values.count];
    for (id value in values) {
      id _Nullable transformedValue = [transformer transformedValue:value];
      LTParameterAssert(transformedValue, @"Transformation of object at index %lu with value %@ "
                        "using transformer %@ returned nil",
                        (unsigned long)[values indexOfObject:value], value, transformer);
      [transformedValues addObject:transformedValue];
    }

    return [transformedValues copy];
  } reverseBlock:^NSArray *(NSArray *transformedValues) {
    if (!transformedValues) {
      return nil;
    }

    LTParameterAssert([transformedValues isKindOfClass:[NSArray class]],
                      @"Expected an array, got: %@", transformedValues.class);

    NSMutableArray *values = [NSMutableArray arrayWithCapacity:transformedValues.count];
    for (id transformedValue in transformedValues) {
      id _Nullable value = [transformer reverseTransformedValue:transformedValue];
      LTParameterAssert(value, @"Reverse transformation of object at index %lu with value %@ "
                        "using transformer %@ returned nil",
                        (unsigned long)[transformedValues indexOfObject:transformedValue],
                        transformedValue, transformer);
      [values addObject:value];
    }

    return [values copy];
  }];
}

+ (NSValueTransformer *)lt_enumNameTransformerForClass:(Class)enumClass {
  LTParameterAssert([enumClass conformsToProtocol:@protocol(LTEnum)], @"Given class %@ doesn't "
                    "conform to the LTEnum protocol", enumClass);

  return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id<LTEnum>(NSString *name) {
    LTParameterAssert(name, @"Given enum name is nil");
    return [[enumClass alloc] initWithName:name];
  } reverseBlock:^NSString *(id<LTEnum> enumObject) {
    LTParameterAssert(enumObject, @"Given enum object is nil");
    return enumObject.name;
  }];
}

@end

NS_ASSUME_NONNULL_END
