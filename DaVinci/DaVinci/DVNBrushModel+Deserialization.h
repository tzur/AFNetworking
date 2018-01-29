// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Category augmenting the \c DVNBrushModel class with functionality to deserialize instances from
/// given JSON dictionaries.
@interface DVNBrushModel (Deserialization)

/// Deserializes and returns the model encoded in the given \c dictionary. If the deserialization
/// does not succeed, returns \c nil and sets the given \c error to an appropriate error. The
/// \c code of the \c error is the \c value of an \c DVNBrushModelErrorCode instance.
+ (nullable instancetype)modelFromJSONDictionary:(NSDictionary *)dictionary
                                           error:(NSError *__autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
