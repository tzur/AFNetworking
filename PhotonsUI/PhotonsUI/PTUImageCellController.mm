// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellController.h"

#import <LTKit/LTCGExtensions.h>

#import "PTUImageCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUImageCellController ()

/// Manual disposal handle for the image signal of the \c viewModel.
@property (strong, nonatomic) RACDisposable *imageSignalDisposable;

/// Manual disposal handle for the title signal of the \c viewModel.
@property (strong, nonatomic) RACDisposable *titleSignalDisposable;

/// Manual disposal handle for the subtitle signal of the \c viewModel.
@property (strong, nonatomic) RACDisposable *subtitleSignalDisposable;

@end

@implementation PTUImageCellController

- (void)dealloc {
  [self.imageSignalDisposable dispose];
  [self.titleSignalDisposable dispose];
  [self.subtitleSignalDisposable dispose];
}

- (void)setImageSize:(CGSize)imageSize {
  if (self.imageSize == imageSize) {
    return;
  }
  
  _imageSize = imageSize;
  [self replaceImageSignalBindingWithoutClearing];
}

- (void)setViewModel:(nullable id<PTUImageCellViewModel>)viewModel {
  _viewModel = viewModel;
  [self replaceTitleSignalBinding];
  [self replaceSubtitleSignalBinding];
  [self replaceImageSignalBinding];
}

#pragma mark -
#pragma mark Title
#pragma mark -

- (void)replaceTitleSignalBinding {
  [self.titleSignalDisposable dispose];
  if ([self.delegate respondsToSelector:@selector(imageCellController:loadedTitle:)]) {
    [self.delegate imageCellController:self loadedTitle:nil];
  }
  [self bindTitleSignal];
}

- (void)bindTitleSignal {
  @weakify(self);
  self.titleSignalDisposable = [[self.viewModel.titleSignal
      deliverOnMainThread]
      subscribeNext:^(NSString *title) {
        @strongify(self);
        if ([self.delegate respondsToSelector:@selector(imageCellController:loadedTitle:)]) {
          [self.delegate imageCellController:self loadedTitle:title];
        }
      } error:^(NSError *error) {
        @strongify(self);
        if ([self.delegate respondsToSelector:@selector(imageCellController:errorLoadingTitle:)]) {
          [self.delegate imageCellController:self errorLoadingTitle:error];
        }
      }];
}

#pragma mark -
#pragma mark Subtitle
#pragma mark -

- (void)replaceSubtitleSignalBinding {
  [self.subtitleSignalDisposable dispose];
  if ([self.delegate respondsToSelector:@selector(imageCellController:loadedSubtitle:)]) {
    [self.delegate imageCellController:self loadedSubtitle:nil];
  }
  [self bindSubtitleSignal];
}

- (void)bindSubtitleSignal {
  @weakify(self);
  self.subtitleSignalDisposable = [[self.viewModel.subtitleSignal
      deliverOnMainThread]
      subscribeNext:^(NSString *subtitle) {
        @strongify(self);
        if ([self.delegate respondsToSelector:@selector(imageCellController:loadedSubtitle:)]) {
          [self.delegate imageCellController:self loadedSubtitle:subtitle];
        }
      } error:^(NSError *error) {
        @strongify(self);
        if ([self.delegate respondsToSelector:
             @selector(imageCellController:errorLoadingSubtitle:)]) {
          [self.delegate imageCellController:self errorLoadingSubtitle:error];
        }
      }];
}

#pragma mark -
#pragma mark Image
#pragma mark -

- (void)replaceImageSignalBinding {
  [self.imageSignalDisposable dispose];
  if ([self.delegate respondsToSelector:@selector(imageCellController:loadedImage:)]) {
    [self.delegate imageCellController:self loadedImage:nil];
  }
  [self bindImageSignal];
}

- (void)replaceImageSignalBindingWithoutClearing {
  [self.imageSignalDisposable dispose];
  [self bindImageSignal];
}

- (void)bindImageSignal {
  @weakify(self);
  if (self.imageSize == CGSizeZero) {
    return;
  }
  
  self.imageSignalDisposable = [[[self.viewModel imageSignalForCellSize:self.imageSize]
      deliverOnMainThread]
      subscribeNext:^(UIImage *image) {
        @strongify(self);
        [self.delegate imageCellController:self loadedImage:image];
      } error:^(NSError *error) {
        @strongify(self);
        if ([self.delegate respondsToSelector:@selector(imageCellController:errorLoadingImage:)]) {
          [self.delegate imageCellController:self errorLoadingImage:error];
        }
      }];
}

@end

NS_ASSUME_NONNULL_END
