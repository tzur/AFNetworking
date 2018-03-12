// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIResourceCell+Protected.h"

NS_ASSUME_NONNULL_BEGIN

@class HUIImageItem;

/// Cell with a single image. The image is scaled to fill the cell's content view bounds. In order
/// for the cell to load image the \c imageLoader property of \c HUISettings must be set. The image
/// is displayed using \c UIImageView, which has "Image" accessibility identifier.
@interface HUIImageCell : HUIResourceCell

/// Help item presented by this cell.
@property (strong, nonatomic, nullable) HUIImageItem *item;

@end

NS_ASSUME_NONNULL_END
