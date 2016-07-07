// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@protocol PTUImageCellViewModel;

/// A dynamic view that alters its content in response to its current dimensions. The view displays
/// an image on the left and two text labels right to it, one on top of each other supplied by the
/// given \c PTUImageCellViewModel object. Setting the view model will first nullify all the
/// properties and then continuously update them according to it. The view queries the view model
/// for a new image signal whenever its size changes.
@interface PTUImageCellView : UIView

/// View model to determine the properties displayed by this view.
@property (strong, nonatomic, nullable) id<PTUImageCellViewModel> viewModel;

/// Currently set title.
@property (readonly, nonatomic, nullable) NSString *title;

/// Currently set subtitle.
@property (readonly, nonatomic, nullable) NSString *subtitle;

/// Currently set image.
@property (readonly, nonatomic, nullable) UIImage *image;

@end

NS_ASSUME_NONNULL_END
