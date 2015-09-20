// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Implemented by classes that support serialization/deserialization of \c NSDictionary from/to
/// them.
@protocol LTJSONSerializing <NSObject>

/// Set of key paths that are involved in the serialization and deserialization phase.
+ (NSSet *)serializableKeyPaths;

@end

/// Adapter for converting from/to dictionary of JSON supported objects (arrays, dictionaries,
/// strings and numbers).
///
/// The following non-plist objects supports conversion:
///   - LTVector[2/3/4].
///   - LTEnum objects.
///   - Objects that inherit from MTLModel and conform to MTLJSONSerializing.
@interface LTJSONSerializationAdapter : NSObject

/// Converts a \c dictionary holding non-plist objects to one that can be serialized to JSON or a
/// plist. Dictionary keys must be of \c NSString type.
+ (NSDictionary *)JSONDictionaryFromDictionary:(NSDictionary *)dictionary;

/// Deserializes a JSON \c dictionary to a dictionary containing Objective-C objects.
/// The specific deserialization class for each object in the dictionary is defined by the given \c
/// objectClass, which must conform to \c LTJSONSerializing. Dictionary keys must be of \c NSString
/// type and be one of the keyPaths in \c serializableKeyPaths.
+ (NSDictionary *)dictionaryFromJSONDictionary:(NSDictionary *)dictionary
                                      forClass:(Class)objectClass;

/// Deserializes the given JSON \c dictionary and merges its values to the given object. Dictionary
/// keys must be of \c NSString type and be one of the keyPaths in \c serializableKeyPaths.
+ (void)mergeJSONDictionary:(NSDictionary *)dictionary
                   toObject:(NSObject<LTJSONSerializing> *)object;

@end
