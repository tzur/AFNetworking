// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTUImageCellViewModel

@synthesize image = _image, title = _title, subtitle = _subtitle;

- (instancetype)initWithImageSignal:(RACSignal *)imageSignal titleSignal:(RACSignal *)titleSignal
                     subtitleSignal:(RACSignal *)subtitleSignal {
  if (self = [super init]) {
    RAC(self, image) = [[[[imageSignal
        filter:^BOOL(id value) {
          return [value isKindOfClass:[UIImage class]];
        }]
        catchTo:[RACSignal empty]]
        takeUntil:[self rac_willDeallocSignal]]
        deliverOnMainThread];

    RAC(self, title) = [[[[titleSignal
        filter:^BOOL(id value) {
          return [value isKindOfClass:[NSString class]];
        }]
        catchTo:[RACSignal empty]]
        takeUntil:[self rac_willDeallocSignal]]
        deliverOnMainThread];

    RAC(self, subtitle) = [[[[subtitleSignal
        filter:^BOOL(id value) {
          return [value isKindOfClass:[NSString class]];
        }]
        catchTo:[RACSignal empty]]
        takeUntil:[self rac_willDeallocSignal]]
        deliverOnMainThread];
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
