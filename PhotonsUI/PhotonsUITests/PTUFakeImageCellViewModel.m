// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUFakeImageCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTUFakeImageCellViewModel

- (instancetype)init {
  return [self initWithImageSignal:nil titleSignal:nil subtitleSignal:nil];
}

- (instancetype)initWithImageSignal:(nullable RACSignal *)imageSignal
                        titleSignal:(nullable RACSignal *)titleSignal
                     subtitleSignal:(nullable RACSignal *)subtitleSignal {
  if (self = [super init]) {
    _imageSignal = imageSignal;
    _titleSignal = titleSignal;
    _subtitleSignal = subtitleSignal;
  }
  return self;
}

- (nullable RACSignal *)imageSignalForCellSize:(CGSize __unused)cellSize {
  return self.imageSignal;
}

@end

NS_ASSUME_NONNULL_END
