// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitObserver.h"

#import <Photos/Photos.h>

#import "NSErrorCodes+Photons.h"
#import "RACSignal+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PHPhotoLibrary (PTNPhotoLibrary)

- (PHAuthorizationStatus)authorizationStatus {
  return [[self class] authorizationStatus];
}

@end

@interface PTNPhotoKitObserver () <PHPhotoLibraryChangeObserver>

/// Photo library used for observation.
@property (readonly, nonatomic) id<PTNPhotoLibrary> photoLibrary;

/// Multicasted changes connection, registers this object as a PhotoKit change observer as a
/// connection side effect, and returns the multicasted observation results.
@property (readonly, nonatomic) RACMulticastConnection *multicastedPhotoLibraryChanges;

@end

@implementation PTNPhotoKitObserver

- (instancetype)initWithPhotoLibrary:(id<PTNPhotoLibrary>)photoLibrary {
  if (self = [super init]) {
    _photoLibrary = photoLibrary;
    
    @weakify(self);
    _multicastedPhotoLibraryChanges = [[[RACSignal
        defer:^RACSignal *{
          @strongify(self);
          [self.photoLibrary registerChangeObserver:self];
          return [[self rac_signalForSelector:@selector(photoLibraryDidChange:)
                                fromProtocol:@protocol(PHPhotoLibraryChangeObserver)]
              reduceEach:^(PHChange *change) {
                return change;
              }];
        }]
        takeUntil:[self rac_willDeallocSignal]]
        publish];
  }
  return self;
}

- (RACSignal *)photoLibraryChanged {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    if ([self.photoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
      return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeNotAuthorized]];
    }
    
    [self.multicastedPhotoLibraryChanges connect];
    return self.multicastedPhotoLibraryChanges.signal;
  }];
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
