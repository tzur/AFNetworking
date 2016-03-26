// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitFakeObserver.h"

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTNPhotoKitFakeObserver ()

/// Subject to send fake changes on.
@property (strong, nonatomic) RACSubject *photoLibrarySubject;

@end

@implementation PTNPhotoKitFakeObserver

- (instancetype)init {
  if (self = [super init]) {
    self.photoLibrarySubject = [RACReplaySubject subject];
  }
  return self;
}

- (RACSignal *)photoLibraryChanged {
  return self.photoLibrarySubject;
}

- (void)sendChange:(PHChange *)change {
  [self.photoLibrarySubject sendNext:change];
}

@end

NS_ASSUME_NONNULL_END
