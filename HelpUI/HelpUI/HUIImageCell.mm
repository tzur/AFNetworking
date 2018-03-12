// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIImageCell.h"

#import <LTKit/LTImageLoader.h>

#import "HUIBoxView.h"
#import "HUIItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUIImageCell ()

/// View for showing the content image.
@property (readonly, nonatomic) UIImageView *imageView;

/// Image loader used to load the content image.
@property (readonly, nonatomic) LTImageLoader *imageLoader;

@end

@implementation HUIImageCell

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setup];
  }
  return self;
}

- (void)setup {
  [self setupImageLoader];
  [self setupImageView];
}

- (void)setupImageLoader {
  _imageLoader = [HUISettings instance].imageLoader;
  LTAssert(_imageLoader, @"Instance of LTImageLoader in not available. The default injector must "
           "be configured to provide such instance");
}

- (void)setupImageView {
  _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
  self.imageView.accessibilityIdentifier = @"Image";
  self.imageView.contentMode = UIViewContentModeScaleAspectFill;

  [self.boxView.contentView addSubview:self.imageView];
  [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.boxView.contentView);
  }];
}

#pragma mark -
#pragma mark UICollectionReusableView
#pragma mark -

- (void)prepareForReuse {
  [super prepareForReuse];
  self.item = nil;
}

#pragma mark -
#pragma mark Item
#pragma mark -

- (void)setItem:(nullable HUIImageItem *)item {
  if (item == _item) {
    return;
  }

  _item = item;
  self.boxView.title = item.title;
  self.boxView.body = item.body;
  self.boxView.iconURL = item.iconURL;
  self.imageView.hidden = YES;
  self.imageView.image = nil;

  if (!item) {
    return;
  }

  auto image = [self.imageLoader imageNamed:item.image];
  if (!image) {
    LogWarning(@"Could not load image resource '%@'", item.image);
    return;
  }

  self.imageView.hidden = NO;
  [UIView animateWithDuration:0.25 animations:^{
    self.imageView.image = image;
  }];
}

@end

NS_ASSUME_NONNULL_END
