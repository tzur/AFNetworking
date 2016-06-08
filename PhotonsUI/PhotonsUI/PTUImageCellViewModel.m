// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTUImageCellViewModel

@synthesize imageSignal = _imageSignal;
@synthesize titleSignal = _titleSignal;
@synthesize subtitleSignal = _subtitleSignal;

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

@end

NS_ASSUME_NONNULL_END
