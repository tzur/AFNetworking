// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUCollectionView.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTUCollectionView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self buildViews];
  }
  return self;
}

- (void)buildViews {
  [self buildCollectionViewController];
  self.emptyView = [PTUCollectionView defaultEmptyView];
  self.errorView = [PTUCollectionView defaultErrorView];
}

- (void)buildCollectionViewController {
  _collectionViewContainer = [[UIView alloc] initWithFrame:CGRectZero];
  self.collectionViewContainer.accessibilityIdentifier = @"CollectionViewContainer";
  self.collectionViewContainer.backgroundColor = [UIColor clearColor];
  [self addSubview:self.collectionViewContainer];
  [self.collectionViewContainer mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self);
  }];
}

+ (UIView *)defaultEmptyView {
  UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];

  UILabel *noPhotosLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  noPhotosLabel.text = _LDefault(@"No Photos", @"Label presented instead of content in an empty "
                                 "album, indicating it has no photos");
  noPhotosLabel.textAlignment = NSTextAlignmentCenter;
  noPhotosLabel.font = [UIFont italicSystemFontOfSize:15];
  noPhotosLabel.textColor = [UIColor lightGrayColor];

  [emptyView addSubview:noPhotosLabel];
  [noPhotosLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.equalTo(emptyView.mas_top).with.offset(44);
    make.centerX.equalTo(emptyView);
  }];

  return emptyView;
}

+ (UIView *)defaultErrorView {
  UIView *errorView = [[UIView alloc] initWithFrame:CGRectZero];

  UILabel *errorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  errorLabel.text = _LDefault(@"Whoops! Something went wrong", @"Label presented instead of "
                              "content in an album when it couldn't be fetched due to an error");
  errorLabel.textAlignment = NSTextAlignmentCenter;
  errorLabel.font = [UIFont italicSystemFontOfSize:15];
  errorLabel.textColor = [UIColor lightGrayColor];

  [errorView addSubview:errorLabel];
  [errorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.equalTo(errorView.mas_top).with.offset(44);
    make.centerX.equalTo(errorView);
  }];

  return errorView;
}

#pragma mark -
#pragma mark Setters
#pragma mark -

- (void)setEmptyView:(UIView *)emptyView {
  [self.emptyView removeFromSuperview];

  _emptyView = emptyView;
  self.emptyView.accessibilityIdentifier = @"Empty";
  [self insertSubview:self.emptyView aboveSubview:self.collectionViewContainer];
  [self addSubview:self.emptyView];
  [self.emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self);
  }];
}

- (void)setErrorView:(UIView *)errorView {
  [self.errorView removeFromSuperview];

  _errorView = errorView;
  self.errorView.accessibilityIdentifier = @"Error";
  [self insertSubview:self.errorView aboveSubview:self.collectionViewContainer];
  [self addSubview:self.errorView];
  [self.errorView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self);
  }];
}

- (void)setBackgroundView:(nullable UIView *)backgroundView {
  [_backgroundView removeFromSuperview];

  _backgroundView = backgroundView;
  if (backgroundView) {
    [self insertSubview:backgroundView belowSubview:self.collectionViewContainer];
    [backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(self);
    }];
  }
}

- (void)setBackgroundColor:(UIColor *)color {
  self.collectionViewContainer.backgroundColor = color;
}

- (UIColor *)backgroundColor {
  return self.collectionViewContainer.backgroundColor;
}

@end

NS_ASSUME_NONNULL_END
