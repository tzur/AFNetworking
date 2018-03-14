// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "HUIItemsDataSource.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake data source that uses an array of arrays as its source. The data source cells is of the
/// type \c HUIFakeCell.
@interface HUIFakeDataSource : NSObject <HUIItemsDataSource>

/// Initializes with array of arrays of strings to be used as the source of the data. Top level
/// array defines sections, and the subarrays - cells. The cells are of type \c HUIFakeCell and
/// their values are defined by the strings in the arrays.
- (instancetype)initWithArrayOfArrays:(NSArray<NSArray<NSString *> *> *)arrays;

/// Array of arrays of strings that defines the source of the data. Top level array defines
/// sections, and the subarrays - cells. The cells are of type \c HUIFakeCell and their values are
/// defined by the strings in the arrays.
@property (strong, nonatomic) NSMutableArray<NSArray<NSString *> *> *arrays;

@end

NS_ASSUME_NONNULL_END
