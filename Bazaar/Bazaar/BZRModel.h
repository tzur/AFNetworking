// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// An \c MTLModel that provides safer initialization by performing validations in the initializer
@interface BZRModel : MTLModel

/// Initializes with \c dictionaryValue, used to set properties of this class with. \c nil is
/// returned and \c error is set in case of failure in initialization.
///
/// @note Prior to initialization the dictionary is being validated for presence of mandatory
/// properties, i.e. it is validated that the dictionary contains non-null values for all mandatory
/// properties of the model. Mandatory properties are properties that aren't optional and don't have
/// default values. Optional properties can be specified by overriding
/// \c +[BZRModel optionalPropertyKeys], and default values can be specified by overriding
/// \c +[BZRModel defaultPropertyValues].
///
/// @note After initialization, \c -[MTLModel validate:] is invoked. This is a hook for the model
/// class to apply specialized validation (e.g. validating the combination of some model values).
- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionaryValue
                                      error:(NSError * __autoreleasing *)error;

/// Returns the set of optional property keys for this model class. The default return value is an
/// empty set, subclasses should override this method and return their own set of optional property
/// keys.
+ (NSSet<NSString *> *)optionalPropertyKeys;

/// Returns a dictionary of property keys mapped to values which are the default values for this
/// model class. The default return value is an empty dictionary. Subclasses should override this
/// method and return their own dictionary of default property values.
+ (NSDictionary<NSString *, id> *)defaultPropertyValues;

/// Validates that the given \c dictionaryValue can be safely deserialized to an instance of the
/// receiver class while preserving the nullability attributes of the model properties. All model
/// properties are assumed to be mandatory except for those listed in \c optionalPropertyKeys. If
/// validation fails \c NO is returned and \c error, if not \c nil, will point to an \c NSError
/// object describing the error.
+ (BOOL)validateDictionaryValue:(NSDictionary *)dictionaryValue
       withOptionalPropertyKeys:(NSSet<NSString *> *)optionalPropertyKeys
                          error:(NSError **)error;

/// Returns a new \c BZRModel with the property named \c propertyName set to \c value.
- (instancetype)modelByOverridingProperty:(NSString *)propertyName withValue:(nullable id)value;

/// Returns a new \c BZRModel with the property at \c keypath set to \c value. \c keypath
/// supports specifying index of an object in an array property, e.g.
/// "arrayProperty[1].primitiveProperty".
///
/// An \c NSInternalInconsistencyException is raised if there was an error while creating the
/// modified model and an \c NSInvalidArgumentException is raised if the given \c keypath is
/// invalid. Any component in the path except for the last one must be a \c BZRModel or an \c
/// NSArray of \c BZRModels..
- (instancetype)modelByOverridingPropertyAtKeypath:(NSString *)keypath withValue:(nullable id)value;

@end

NS_ASSUME_NONNULL_END
