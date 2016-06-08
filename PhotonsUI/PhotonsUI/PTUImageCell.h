// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

@protocol PTUImageCellViewModel;

NS_ASSUME_NONNULL_BEGIN

/// A dynamic UICollectionView cell that alters its content in response to its current dimensions.
/// The cell displays an image on the left and two text labels right to it, one on top of each
/// other.
@interface PTUImageCell : UICollectionViewCell

/// View model to determine the properties displayed by this cell. Changing the view model will
/// first set all the relevant properties to \c nil followed by the latest value sent from each
/// signal of the \c viewModel. Errors on these signals are mapped to \c nil and all values are
/// explicitly delivered on the main thread.
- (void)setViewModel:(nullable id<PTUImageCellViewModel>)viewModel;

/// Currently set title.
@property (readonly, nonatomic, nullable) NSString *title;

/// Currently set subtitle.
@property (readonly, nonatomic, nullable) NSString *subtitle;

/// Currently set image.
@property (readonly, nonatomic, nullable) UIImage *image;

@end

NS_ASSUME_NONNULL_END
