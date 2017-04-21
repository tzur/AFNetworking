// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Reversible transformer that converts \c NSString class name to its corresponding \c Class
/// object. Raises \c NSInvalidArgumentException if the class name does not correspond to a class.
extern NSString * const kLTClassValueTransformer;

/// Reversible transformer that converts a model to its Objective-C representation and vice versa.
/// The input to the forward transformer must be of one of the following types:
///
///   - \c NSString or \c NSNumber: will be returned as-is by the transformer.
///
///   - \c LTEnum: a JSON dictionary that must contain the keys \c _class and \c name with an
///     \c NSString value of the enum class name and the enum field name, accordingly.
///
///   - \c NSDictionary: a JSON dictionary of an \c MTLModel to the appropriate model object. The
///     dictionary must contain the key \c _class with an \c NSString value of the model class name,
///     which must be a subclass of \c MTLModel and conform to \c MTLJSONSerializing.
///
/// If the input is not one of these types, or the specific type conditions fail,
/// \c NSInvalidArgumentException will be raised.
extern NSString * const kLTModelValueTransformer;

/// Key used by \c kLTModelValueTransformer whose value represents the class of the object to be
/// deserialized from the given serialized dictionary.
extern NSString * const kLTModelValueTransformerClassKey;

/// Key used by \c kLTModelValueTransformer whose value represents the name of the enum field to
/// deserialize.
extern NSString * const kLTModelValueTransformerEnumNameKey;

/// Reversible transformer that converts \c NSString color representation to its corresponding
/// \c UIColor object or vice versa.
///
/// The input to the forward transformer must be a \c NSString in the following formats:
/// #RGB, #ARGB, #RRGGBB, or #AARRGGBB.
///
/// The input to the reverse transformer must be a \c UIColor.
///
/// If the input is \c nil, or not one of these types, or the specific type conditions fail,
/// \c NSInvalidArgumentException will be raised.
extern NSString * const kLTColorValueTransformer;

/// Returns a reversible transformer that converts \c NSString UUID representation to its
/// corresponding \c NSUUID and vice versa.
///
/// The input to the forward transformer must be an \c NSString with the following format:
/// \c 123e4567-e89b-12d3-a456-426655440000.
///
/// The input to the reverse transformer must be an \c NSUUID.
///
/// If the input is \c nil, returns \c nil. If the specific type conditions fail,
/// \c NSInvalidArgumentException will be raised.
///
/// @note The output of the transformation from \c NSUUID to \c NSString is upper case.
extern NSString * const kLTUUIDValueTransformer;

/// Returns a reversible transformer that converts \c NSString date representation to its
/// corresponding \c NSDate and vice versa.
///
/// The input to the forward transformer must be a \c NSString with the following format:
/// <tt>yyyy-MM-dd'T'HH:mm:ss.SSS'Z'</tt>.
///
/// The input to the reverse transformer must be a \c NSDate.
///
/// If the input is \c nil, or not one of these types, or the specific type conditions fail,
/// \c NSInvalidArgumentException will be raised.
extern NSString * const kLTUTCDateValueTransformer;

/// Returns a reversible transformer that converts \c NSString of a timezone name to its
/// corresponding \c NSTimeZone and vice versa.
///
/// The input to the forward transformer must be a \c NSString from:
///
/// @code
/// [NSTimeZone knownTimeZoneNames];
/// @endcode
///
/// The input to the reverse transformer must be a \c NSTimeZone.
///
/// If the input is \c nil, or not one of these types, or the specific type conditions fail,
/// \c NSInvalidArgumentException will be raised.
extern NSString * const kLTTimeZoneValueTransformer;

/// Returns a reversible transformer that converts an \c NSString path representation to its
/// corresponding \c LTPath and vice versa.
///
/// The input to the forward transformer must be an \c NSString.
///
/// The input to the reverse transformer must be an \c LTPath.
///
/// If the input is \c nil, or not one of these types, or the specific type conditions fail,
/// \c NSInvalidArgumentException will be raised.
extern NSString * const kLTPathValueTransformer;

/// Returns a reversible transformer that converts an \c NSString URL representation to its
/// corresponding \c NSURL and vice versa.
///
/// The input to the forward transformer must be an \c NSString describing a URL. The string may
/// contain unicode and characters that must be percent encoded. The output will contain percent
/// encoded characters only for characters which are in \c URLQueryAllowedCharacterSet.
///
/// The input to the reverse transformer must an \c NSURL.
///
/// If the input is \c nil, or not one of these types, or the specific type conditions fail,
/// \c NSInvalidArgumentException will be raised.
extern NSString * const kLTURLValueTransformer;

@interface NSValueTransformer (LTEngine)

/// Reversible transformer that accepts a JSON dictionary with \c NSString as keys and
/// \c NSDictionary as values, where each value is an \c MTLModel of the given \c modelClass. The
/// transformation returns a \c NSDictionary that maps the input keys to a deserialized objects with
/// type \c modelClass. Raises \c NSInvalidArgumentException if the transformed value is not
/// \c NSDictionary, if the keys are not \c NSString or if the serialization or deserialization of
/// one of the values failed.
///
/// For example, given the model:
/// @code
/// @interface MyModel : MTLModel
///
/// - (instancetype)initWithKey:(NSString *)key number:(NSNumber *)number;
///
/// @property (readonly, nonatomic) NSString *key;
///
/// @property (readonly, nonatomic) NSNumber *number;
///
/// @end
/// @endcode
///
/// The following JSON:
/// @code
/// @{
///   @"foo": @{
///     @"key": @"towel",
///     @"number": @42
///   },
///   @"bar": @{
///     @"key": @"prime",
///     @"number": @7
///   }
/// }
/// @endcode
///
/// And the transformer:
/// @code
/// [NSValueTransformer lt_JSONDictionaryTransformerWithValuesOfModelClass:[MyModel class]];
/// @endcode
///
/// Will yield the deserialized output:
/// @code
/// @{
///   @"foo": [[MyModel alloc] initWithName:@"towel" number:@42],
///   @"bar": [[MyModel alloc] initWithName:@"prime" number:@7]
/// }
/// @endcode
+ (NSValueTransformer *)lt_JSONDictionaryTransformerWithValuesOfModelClass:(Class)modelClass;

/// Reversible transformer that accepts a JSON dictionary with \c NSString as keys and
/// values bidirectionally transformable with \c transformer as values. The transformation returns
/// an \c NSDictionary that maps the input keys to deserialized objects returned from the given
/// value transformer. Raises \c NSInvalidArgumentException if the keys are not \c NSString or if
/// the serialization or deserialization of one of the values failed.
///
/// For example, given the following JSON:
/// @code
/// @{
///   @"foo": @"1970/01/01 00:00:30 +0000",
///   @"bar": @"1970/01/01 00:00:60 +0000"
/// }
/// @endcode
///
/// The transformer:
/// @code
/// [NSValueTransformer lt_JSONDictionaryTransformerWithTransformer:
///     [NSValueTransformerNamed:kLTUTCDateValueTransformer]];
/// @endcode
///
/// Will yield the deserialized output:
/// @code
/// @{
///   @"foo": [NSDate dateWithTimeIntervalSince1970:30],
///   @"bar": [NSDate dateWithTimeIntervalSince1970:60]
/// }
/// @endcode
+ (NSValueTransformer *)lt_JSONDictionaryTransformerWithTransformer:
    (NSValueTransformer *)transformer;

/// Reversible transformer that accepts a JSON array with values bidirectionally transformable with
/// \c transformer. The transformation returns an \c NSArray that maps the values to deserialized
/// objects returned from the given value transformer. Raises \c NSInvalidArgumentException if the
/// serialization or deserialization of one of the values failed.
///
/// For example, given the following JSON:
/// @code
/// @[@"1970/01/01 00:00:30 +0000", @"1970/01/01 00:00:60 +0000"]
/// @endcode
///
/// The transformer:
/// @code
/// [NSValueTransformer lt_JSONArrayTransformerWithTransformer:
///     [NSValueTransformerNamed:kLTUTCDateValueTransformer]];
/// @endcode
///
/// Will yield the deserialized output:
/// @code
/// @[[NSDate dateWithTimeIntervalSince1970:30], [NSDate dateWithTimeIntervalSince1970:60]]
/// @endcode
+ (NSValueTransformer *)lt_JSONArrayTransformerWithTransformer:(NSValueTransformer *)transformer;

/// Returns a reversible transformer that converts an input \c NSString to its \c id<LTEnum>
/// instance (by initializing the enum with its name).
///
/// If the given \c enumClass is \c nil \c NSInvalidArgumentException will be raised.
///
/// If the input to the returned transformer is \c nil, or not one of enum field names,
/// \c NSInvalidArgumentException will be raised.
+ (NSValueTransformer *)lt_enumNameTransformerForClass:(Class)enumClass;

@end

NS_ASSUME_NONNULL_END
