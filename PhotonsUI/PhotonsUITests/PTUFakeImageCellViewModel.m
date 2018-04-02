// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUFakeImageCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTUFakeImageCellViewModel

- (instancetype)init {
  return [self initWithImageSignal:nil playerItemSignal:nil titleSignal:nil subtitleSignal:nil
                    durationSignal:nil traits:nil];
}

- (instancetype)initWithImageSignal:(nullable RACSignal *)imageSignal
                   playerItemSignal:(nullable RACSignal *)playerItemSignal
                        titleSignal:(nullable RACSignal *)titleSignal
                     subtitleSignal:(nullable RACSignal *)subtitleSignal
                     durationSignal:(nullable RACSignal *)durationSignal
                             traits:(nullable NSSet<NSString *> *)traits {
  if (self = [super init]) {
    _imageSignal = imageSignal;
    _playerItemSignal = playerItemSignal;
    _titleSignal = titleSignal;
    _subtitleSignal = subtitleSignal;
    _durationSignal = durationSignal;
    _traits = traits ?: [NSSet set];
  }
  return self;
}

- (nullable RACSignal *)imageSignalForCellSize:(CGSize __unused)cellSize {
  return self.imageSignal;
}

@end

NS_ASSUME_NONNULL_END
