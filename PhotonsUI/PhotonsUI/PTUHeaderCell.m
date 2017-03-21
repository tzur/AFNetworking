// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUHeaderCell.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTUHeaderCell

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self buildLabel];
    self.clipsToBounds = YES;
  }
  return self;
}

- (void)buildLabel {
  _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  [self addSubview:self.titleLabel];
  self.leftOffset = 18;
}

- (void)setLeftOffset:(CGFloat)leftOffset {
  if (leftOffset == _leftOffset) {
    return;
  }

  _leftOffset = leftOffset;
  [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.centerY.equalTo(self);
    make.left.equalTo(self).with.offset(self.leftOffset);
  }];
}

#pragma mark -
#pragma mark PTUHeaderCell
#pragma mark -

- (void)setTitle:(nullable NSString *)title {
  self.titleLabel.text = title;
}

- (nullable NSString *)title {
  return self.titleLabel.text;
}

@end

NS_ASSUME_NONNULL_END
