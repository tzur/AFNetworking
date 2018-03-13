// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIItemsDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@class HUIDocument;

/// Data source for \c HUIView that uses \c HUIDocument as the actual source.
@interface HUIDocumentDataSource : NSObject <HUIItemsDataSource>

/// Initializes the data source with the given \c helpDocument that is used used as the source of
/// help items provided by the data source. If \c nil, provides no data.
- (instancetype)initWithHelpDocument:(nullable HUIDocument *)helpDocument;

/// Help document this data source is using.
@property (readonly, nonatomic, nullable) HUIDocument *helpDocument;

@end

NS_ASSUME_NONNULL_END
