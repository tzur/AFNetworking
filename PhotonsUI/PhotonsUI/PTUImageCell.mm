// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCell.h"

#import "PTUImageCellView.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUImageCell ()

/// View to display in this cell.
@property (readonly, nonatomic) PTUImageCellView *imageCellView;

@end

@implementation PTUImageCell

@synthesize highlightingView = _highlightingView;

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setup];
  }
  return self;
}

#pragma mark -
#pragma mark Setup
#pragma mark -

- (void)setup {
  self.backgroundColor = [UIColor darkGrayColor];
  [self setupImageCellView];
  [self setupHighlightingView];
}

- (void)setupImageCellView {
  _imageCellView = [[PTUImageCellView alloc] initWithFrame:self.contentView.bounds];
  self.imageCellView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
      UIViewAutoresizingFlexibleHeight;
  
  [self.contentView addSubview:self.imageCellView];
}

- (void)setupHighlightingView {
  _highlightingView = [[UIView alloc] initWithFrame:self.contentView.bounds];
  self.highlightingView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
      UIViewAutoresizingFlexibleHeight;
  
  [self.contentView addSubview:self.highlightingView];
}

- (void)setSelected:(BOOL)selected {
  [super setSelected:selected];
  [self updateHighlightingViewVisibility];
}

- (void)setHighlighted:(BOOL)highlighted {
  [super setHighlighted:highlighted];
  [self updateHighlightingViewVisibility];
}

- (void)updateHighlightingViewVisibility {
  self.highlightingView.hidden = !(self.isSelected || self.isHighlighted);
}

- (void)prepareForReuse {
  [super prepareForReuse];
  self.imageCellView.viewModel = nil;
}

- (CGFloat)contentScaleFactor {
  return self.imageCellView.contentScaleFactor;
}

#pragma mark -
#pragma mark View model
#pragma mark -

- (void)setViewModel:(nullable id<PTUImageCellViewModel>)viewModel {
  self.imageCellView.viewModel = viewModel;
}

- (nullable id<PTUImageCellViewModel>)viewModel {
  return self.imageCellView.viewModel;
}

@end

NS_ASSUME_NONNULL_END
