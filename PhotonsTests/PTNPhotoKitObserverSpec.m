// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitObserver.h"

@import Photos;

SpecBegin(PTNPhotoKitObserver)

__block id<PHPhotoLibraryChangeObserver> changeObserver;

__block id photoLibrary;
__block PTNPhotoKitObserver *observer;

beforeEach(^{
  photoLibrary = OCMClassMock([PHPhotoLibrary class]);
  OCMStub([photoLibrary registerChangeObserver:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained id<PHPhotoLibraryChangeObserver> internalChangeObserver;
    [invocation getArgument:&internalChangeObserver atIndex:2];
    changeObserver = internalChangeObserver;
  });

  observer = [[PTNPhotoKitObserver alloc] initWithPhotoLibrary:photoLibrary];
});

it(@"should report photo library changes", ^{
  LLSignalTestRecorder *recorder = [observer.photoLibraryChanged testRecorder];

  PHChange *firstChange = OCMClassMock([PHChange class]);
  [changeObserver photoLibraryDidChange:firstChange];

  PHChange *secondChange = OCMClassMock([PHChange class]);
  [changeObserver photoLibraryDidChange:secondChange];

  expect(recorder.values).to.equal(@[firstChange, secondChange]);
});

SpecEnd
