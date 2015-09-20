// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Holds a collection of transformers used for serializing classes, as well as transformers-related
/// utilities.
///
/// Currently supported transformers:
/// - LTEnum.
/// - LTVector[2|3|4].
@interface LTTransformers : NSObject

/// Returns an \c NSValueTransformer used to serialize and deserialize the given \c objectClass, or
/// \c nil if the \c objectClass doesn't have an associated transformer.
+ (NSValueTransformer *)transformerForClass:(Class)objectClass;

/// Returns an \c NSValueTransformer used to serialize and deserialize the given \c typeEncoding, or
/// \c nil if the \c typeEncoding doesn't have an associated transformer.
+ (NSValueTransformer *)transformerForTypeEncoding:(NSString *)typeEncoding;

/// Block for transforming an item.
typedef id (^LTTransformerBlock)(id item);

/// Returns an \c NSValueTransformer that transforms an array by applying the given block to each
/// item in the array.
+ (NSValueTransformer *)transformerForArrayByApplying:(LTTransformerBlock)itemTransform;

@end
