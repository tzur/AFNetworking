// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitObserver.h"

#import <Photos/Photos.h>

#import "NSErrorCodes+Photons.h"

/// Fake PHPhotoLibrary used for testing.
@interface PTNFakePHPhotoLibrary : NSObject <PTNPhotoLibrary>

/// Sends \c change to all registered change observers.
- (void)sendChange:(PHChange *)change;

/// Current authorization status, initially set to \c PHAuthorizationStatusAuthorized.
@property (readwrite, nonatomic) PHAuthorizationStatus authorizationStatus;

/// Currently registered change observers. These observers are held weakly.
@property (strong, nonatomic) NSHashTable<id<PHPhotoLibraryChangeObserver>> *changeObservers;

@end

@implementation PTNFakePHPhotoLibrary

- (instancetype)init {
  self.authorizationStatus = PHAuthorizationStatusAuthorized;
  self.changeObservers = [NSHashTable weakObjectsHashTable];
  return self;
}

- (void)registerChangeObserver:(id<PHPhotoLibraryChangeObserver>)observer {
  [self.changeObservers addObject:observer];
}

- (void)unregisterChangeObserver:(id<PHPhotoLibraryChangeObserver>)observer {
  [self.changeObservers removeObject:observer];
}

- (void)sendChange:(PHChange *)change {
  for (id<PHPhotoLibraryChangeObserver> observer in self.changeObservers) {
    [observer photoLibraryDidChange:change];
  }
}

@end

SpecBegin(PTNPhotoKitObserver)

__block PTNFakePHPhotoLibrary *photoLibrary;
__block PTNPhotoKitObserver *observer;

beforeEach(^{
  photoLibrary = [[PTNFakePHPhotoLibrary alloc] init];
  observer = [[PTNPhotoKitObserver alloc] initWithPhotoLibrary:photoLibrary];
});

it(@"should return error when requesing chanegs without authorization", ^{
  photoLibrary.authorizationStatus = PHAuthorizationStatusNotDetermined;
  expect(observer.photoLibraryChanged).will.matchError(^BOOL(NSError *error) {
    return error.lt_isLTDomain && error.code == PTNErrorCodeNotAuthorized;
  });

  photoLibrary.authorizationStatus = PHAuthorizationStatusDenied;
  expect(observer.photoLibraryChanged).will.matchError(^BOOL(NSError *error) {
    return error.lt_isLTDomain && error.code == PTNErrorCodeNotAuthorized;
  });

  photoLibrary.authorizationStatus = PHAuthorizationStatusRestricted;
  expect(observer.photoLibraryChanged).will.matchError(^BOOL(NSError *error) {
    return error.lt_isLTDomain && error.code == PTNErrorCodeNotAuthorized;
  });
});

it(@"should not subscribe to photo library changes before subscribed to", ^{
  RACSignal *changes = observer.photoLibraryChanged;
  expect(photoLibrary.changeObservers.allObjects).to.equal(@[]);

  [changes subscribeNext:^(id) {}];
  expect(photoLibrary.changeObservers.allObjects).to.equal(@[observer]);
});

it(@"should not register change observer if not authorized", ^{
  RACSignal *changes = observer.photoLibraryChanged;
  expect(photoLibrary.changeObservers.allObjects).to.equal(@[]);

  photoLibrary.authorizationStatus = PHAuthorizationStatusDenied;
  [changes subscribeNext:^(id) {}];
  expect(photoLibrary.changeObservers.allObjects).to.equal(@[]);
});

it(@"should not register new observer for every subscription", ^{
  RACSignal *changes = observer.photoLibraryChanged;

  [changes subscribeNext:^(id) {}];
  expect(photoLibrary.changeObservers.allObjects).to.equal(@[observer]);

  [changes subscribeNext:^(id) {}];
  expect(photoLibrary.changeObservers.allObjects).to.equal(@[observer]);
});

it(@"should not register new observer for every signal", ^{
  [observer.photoLibraryChanged subscribeNext:^(id) {}];
  expect(photoLibrary.changeObservers.allObjects).to.equal(@[observer]);

  [observer.photoLibraryChanged subscribeNext:^(id) {}];
  expect(photoLibrary.changeObservers.allObjects).to.equal(@[observer]);
});

it(@"should unregister observer on dealloc", ^{
  @autoreleasepool {
    PTNPhotoKitObserver *deallocatedObserver =
        [[PTNPhotoKitObserver alloc] initWithPhotoLibrary:photoLibrary];
    [deallocatedObserver.photoLibraryChanged subscribeNext:^(id) {}];
    expect(photoLibrary.changeObservers.allObjects).to.equal(@[deallocatedObserver]);
  }

  expect(photoLibrary.changeObservers.allObjects).to.equal(@[]);
});

it(@"should report photo library changes", ^{
  LLSignalTestRecorder *recorder = [observer.photoLibraryChanged testRecorder];

  PHChange *firstChange = OCMClassMock([PHChange class]);
  [photoLibrary sendChange:firstChange];

  PHChange *secondChange = OCMClassMock([PHChange class]);
  [photoLibrary sendChange:secondChange];

  expect(recorder.values).to.equal(@[firstChange, secondChange]);
});

SpecEnd
