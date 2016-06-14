// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAssetManager, PTNDescriptor, PTUImageCellViewModel;

/// Protocol for providers of image cell view models.
@protocol PTUImageCellViewModelProvider <NSObject>

/// Creates and returns a \c PTUImageCellViewModel conforming object that represents \c descriptor
/// in a cell of size \c cellSize pixels.
- (id<PTUImageCellViewModel>)viewModelWithDescriptor:(id<PTNDescriptor>)descriptor
                                            cellSize:(CGSize)cellSize;

@end

NS_ASSUME_NONNULL_END
