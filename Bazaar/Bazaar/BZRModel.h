// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// An \c MTLModel that provides safer initialization by performing 2 validations:
/// 1) Prior to initialization the dictionary is being validated for presence of mandatory
///    properties, i.e. it is validated that the dictionary contains non-null values for all
///    mandatory properties of the model (optional properties can be specified by overriding
///    \c +[BZRModel optionalPropertyKeys]).
/// 2) Post initialization validation by invoking \c -[MTLModel validate:], this is a hook for the
///    model class to apply specialized validation (e.g. validating the combination of some model
///    values).
@interface BZRModel : MTLModel

/// Returns the set of optional property keys for this model class. The default return value is an
/// empty set, subclasses should override this method and return their own set of optional property
/// keys.
+ (NSSet<NSString *> *)optionalPropertyKeys;

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

@end

NS_ASSUME_NONNULL_END
