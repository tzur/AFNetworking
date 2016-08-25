// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for collection view header cells to conform to in order to be used by the Photons
/// framework.
@protocol PTUHeaderCell <NSObject>

/// Title presented by the receiver.
@property (strong, nonatomic, nullable) NSString *title;

@end

/// Default implementation of \c PTUHeaderCell, containing a single label used to display the given
/// \c title. The label is vertically centered and horizontally matching the left of this view with
/// \c leftOffset.
@interface PTUHeaderCell : UICollectionReusableView <PTUHeaderCell>

/// Label used to display \c title.
@property (readonly, nonatomic) UILabel *titleLabel;

/// Left alignment offset of \c titleLabel, initial value is \c 18 points.
@property (nonatomic) CGFloat leftOffset;

@end

NS_ASSUME_NONNULL_END
