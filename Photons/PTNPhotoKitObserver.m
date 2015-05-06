// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitObserver.h"

@import Photos;

NS_ASSUME_NONNULL_BEGIN

@interface PTNPhotoKitObserver () <PHPhotoLibraryChangeObserver>

/// Photo library used for observation.
@property (strong, nonatomic) PHPhotoLibrary *photoLibrary;

/// Returns an infinite signal of \c PHChange objects, which are delivered when there's a change in
/// PhotoKit's library.
@property (strong, readwrite, nonatomic) RACSignal *photoLibraryChanged;

@end

@implementation PTNPhotoKitObserver

- (instancetype)initWithPhotoLibrary:(PHPhotoLibrary *)photoLibrary {
  if (self = [super init]) {
    self.photoLibraryChanged = [[self rac_signalForSelector:@selector(photoLibraryDidChange:)
                                               fromProtocol:@protocol(PHPhotoLibraryChangeObserver)]
        reduceEach:^(PHChange *change) {
          return change;
        }];

    self.photoLibrary = photoLibrary;
    [self.photoLibrary registerChangeObserver:self];
  }
  return self;
}

- (void)dealloc {
  [self.photoLibrary unregisterChangeObserver:self];
}

#pragma mark -
#pragma mark PHPhotoLibraryChangeObserver
#pragma mark -

- (void)photoLibraryDidChange:(PHChange __unused *)changeInstance {
  // Required to avoid compiler warning.
}

@end

NS_ASSUME_NONNULL_END
