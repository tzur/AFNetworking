// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTOpenCVExtensions.h"

NS_ASSUME_NONNULL_BEGIN

/// Value class mapping keys of \c NSString to rows of a two-dimensional, real-valued matrix.
@interface LTParameterizationKeyToValues : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c keys and the given \c valuesPerKey. The number of \c keys must
/// equal the number of rows of the given \c valuesPerKey matrix. Keys map to matrix rows according
/// to the order of the given \c keys.
- (instancetype)initWithKeys:(NSOrderedSet<NSString *> *)keys
                valuesPerKey:(const cv::Mat1g &)valuesPerKey NS_DESIGNATED_INITIALIZER;

/// Returns the values of the matrix row determined by the given \c key.
- (CGFloats)valuesForKey:(NSString *)key;

/// Returns the values of the matrix row determined by the given \c key, at the given \c indices.
/// Every index of the given \c indices must be smaller than the number of columns of the matrix.
- (CGFloats)valuesForKey:(NSString *)key atIndices:(const std::vector<NSUInteger> &)indices;

/// Keys mapping to the corresponding values, stored in the matrix rows.
@property (readonly, nonatomic) NSOrderedSet<NSString *> *keys;

/// Number of values per key, equal to the number of matrix columns.
@property (readonly, nonatomic) int numberOfValuesPerKey;

/// Matrix provided upon initialization, each of whose rows is associated with the corresponding key
/// of \c keys.
@property (readonly, nonatomic) const cv::Mat1g &valuesPerKey;

@end

NS_ASSUME_NONNULL_END
