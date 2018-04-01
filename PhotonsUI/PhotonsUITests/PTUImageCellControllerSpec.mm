// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellController.h"

#import "PTNDisposableRetainingSignal.h"
#import "PTNTestUtils.h"
#import "PTUFakeImageCellViewModel.h"
#import "PTUImageCellViewModel.h"

SpecBegin(PTUImageCellController)

__block PTUImageCellController *imageCellController;
__block id<PTUImageCellControllerDelegate> delegate;

__block PTUFakeImageCellViewModel *viewModel;
__block UIImage *image;
__block RACSubject *imageSubject;
__block RACSubject *titleSubject;
__block RACSubject *subtitleSubject;
__block RACSubject *durationSubject;

beforeEach(^{
  image = [[UIImage alloc] init];

  imageSubject = [RACSubject subject];
  titleSubject = [RACSubject subject];
  subtitleSubject = [RACSubject subject];
  durationSubject = [RACSubject subject];
  viewModel = [[PTUFakeImageCellViewModel alloc] initWithImageSignal:imageSubject
                                                    playerItemSignal:nil
                                                         titleSignal:titleSubject
                                                      subtitleSignal:subtitleSubject
                                                      durationSignal:durationSubject
                                                              traits:nil];

  delegate = OCMProtocolMock(@protocol(PTUImageCellControllerDelegate));
  imageCellController = [[PTUImageCellController alloc] init];
  imageCellController.delegate = delegate;
  [imageCellController setViewModel:viewModel];
  imageCellController.imageSize = CGSizeMake(10, 10);
});

it(@"should not fetch images when given cell size is zero", ^{
  imageCellController.imageSize = CGSizeZero;
  [[(OCMockObject *)delegate reject] imageCellController:imageCellController loadedImage:image];
  [imageSubject sendNext:image];
});

it(@"should update image according to view model", ^{
  imageCellController.imageSize = CGSizeMake(10, 10);
  UIImage *otherImage = [[UIImage alloc] init];

  [imageSubject sendNext:image];
  OCMVerify([delegate imageCellController:imageCellController loadedImage:image]);
  [imageSubject sendNext:otherImage];
  OCMVerify([delegate imageCellController:imageCellController loadedImage:otherImage]);
});

it(@"should request correct image size when cell size changes", ^{
  id<PTUImageCellViewModel> viewModel = OCMProtocolMock(@protocol(PTUImageCellViewModel));
  imageCellController.viewModel = viewModel;
  OCMVerify([viewModel imageSignalForCellSize:CGSizeMake(10, 10)]);

  imageCellController.imageSize = CGSizeMake(20, 10);
  OCMVerify([viewModel imageSignalForCellSize:CGSizeMake(20, 10)]);

  imageCellController.imageSize = CGSizeMake(100, 100);
  OCMVerify([viewModel imageSignalForCellSize:CGSizeMake(100, 100)]);
});

it(@"should update title according to view model", ^{
  [titleSubject sendNext:@"foo"];
  OCMVerify([delegate imageCellController:imageCellController loadedTitle:@"foo"]);
  [titleSubject sendNext:@"bar"];
  OCMVerify([delegate imageCellController:imageCellController loadedTitle:@"bar"]);
});

it(@"should update subtitle according to view model", ^{
  [subtitleSubject sendNext:@"foo"];
  OCMVerify([delegate imageCellController:imageCellController loadedSubtitle:@"foo"]);
  [subtitleSubject sendNext:@"bar"];
  OCMVerify([delegate imageCellController:imageCellController loadedSubtitle:@"bar"]);
});

it(@"should update duration according to view model", ^{
  [durationSubject sendNext:@"foo"];
  OCMVerify([delegate imageCellController:imageCellController loadedDuration:@"foo"]);
  [durationSubject sendNext:@"bar"];
  OCMVerify([delegate imageCellController:imageCellController loadedDuration:@"bar"]);
});

it(@"should map errors on the view model's image signal to delegate calls", ^{
  NSError *error = [NSError lt_errorWithCode:1337];
  [imageSubject sendError:error];
  OCMVerify([delegate imageCellController:imageCellController errorLoadingImage:error]);
});

it(@"should map errors on the view model's title signal to delegate calls", ^{
  NSError *error = [NSError lt_errorWithCode:1337];
  [titleSubject sendError:error];
  OCMVerify([delegate imageCellController:imageCellController errorLoadingTitle:error]);
});

it(@"should map errors on the view model's subtitle signal to delegate calls", ^{
  NSError *error = [NSError lt_errorWithCode:1337];
  [subtitleSubject sendError:error];
  OCMVerify([delegate imageCellController:imageCellController errorLoadingSubtitle:error]);
});

it(@"should map errors on the view model's duration signal to delegate calls", ^{
  NSError *error = [NSError lt_errorWithCode:1337];
  [durationSubject sendError:error];
  OCMVerify([delegate imageCellController:imageCellController errorLoadingDuration:error]);
});

it(@"should stop taking values from previous view model once changed", ^{
  [[(OCMockObject *)delegate reject] imageCellController:imageCellController loadedImage:image];
  [[(OCMockObject *)delegate reject] imageCellController:imageCellController loadedTitle:@"foo"];
  [[(OCMockObject *)delegate reject] imageCellController:imageCellController loadedSubtitle:@"bar"];
  [[(OCMockObject *)delegate reject] imageCellController:imageCellController loadedDuration:@"baz"];

  PTUFakeImageCellViewModel *otherViewModel = [[PTUFakeImageCellViewModel alloc] init];
  imageCellController.viewModel = otherViewModel;

  [imageSubject sendNext:image];
  [titleSubject sendNext:@"foo"];
  [subtitleSubject sendNext:@"bar"];
  [durationSubject sendNext:@"baz"];
});

it(@"should take values from new view model once changed", ^{
  RACSubject *newImageSubject = [RACSubject subject];
  RACSubject *newTitleSubject = [RACSubject subject];
  RACSubject *newSubtitleSubject = [RACSubject subject];
  RACSubject *newDurationSubject = [RACSubject subject];

  PTUFakeImageCellViewModel *otherViewModel =
      [[PTUFakeImageCellViewModel alloc] initWithImageSignal:newImageSubject
                                            playerItemSignal:nil
                                                 titleSignal:newTitleSubject
                                              subtitleSignal:newSubtitleSubject
                                              durationSignal:newDurationSubject
                                                      traits:nil];
  imageCellController.viewModel = otherViewModel;

  [newImageSubject sendNext:image];
  [newTitleSubject sendNext:@"foo"];
  [newSubtitleSubject sendNext:@"bar"];
  [newDurationSubject sendNext:@"baz"];

  OCMVerify([delegate imageCellController:imageCellController loadedImage:image]);
  OCMVerify([delegate imageCellController:imageCellController loadedTitle:@"foo"]);
  OCMVerify([delegate imageCellController:imageCellController loadedSubtitle:@"bar"]);
  OCMVerify([delegate imageCellController:imageCellController loadedDuration:@"baz"]);
});

it(@"should clear values when setting a new view model", ^{
  imageCellController.viewModel = nil;
  OCMVerify([delegate imageCellController:imageCellController loadedImage:nil]);
  OCMVerify([delegate imageCellController:imageCellController loadedTitle:nil]);
  OCMVerify([delegate imageCellController:imageCellController loadedSubtitle:nil]);
  OCMVerify([delegate imageCellController:imageCellController loadedDuration:nil]);
});

context(@"memory management", ^{
  __block PTNDisposableRetainingSignal *imageSignal;
  __block PTNDisposableRetainingSignal *titleSignal;
  __block PTNDisposableRetainingSignal *subtitleSignal;
  __block PTNDisposableRetainingSignal *durationSignal;
  __block PTUFakeImageCellViewModel *disposableViewModel;

  beforeEach(^{
    imageSignal = PTNCreateDisposableRetainingSignal();
    titleSignal = PTNCreateDisposableRetainingSignal();
    subtitleSignal = PTNCreateDisposableRetainingSignal();
    durationSignal = PTNCreateDisposableRetainingSignal();
    disposableViewModel = [[PTUFakeImageCellViewModel alloc] initWithImageSignal:imageSignal
                                                                playerItemSignal:nil
                                                                     titleSignal:titleSignal
                                                                  subtitleSignal:subtitleSignal
                                                                  durationSignal:durationSignal
                                                                          traits:nil];
  });

  it(@"should dispose subscriptions when changing view model", ^{
    imageCellController.viewModel = disposableViewModel;

    expect(imageSignal.disposables.count).to.equal(1);
    expect(titleSignal.disposables.count).to.equal(1);
    expect(subtitleSignal.disposables.count).to.equal(1);
    expect(durationSignal.disposables.count).to.equal(1);
    expect(imageSignal.disposables.firstObject.disposed).to.beFalsy();
    expect(titleSignal.disposables.firstObject.disposed).to.beFalsy();
    expect(subtitleSignal.disposables.firstObject.disposed).to.beFalsy();
    expect(durationSignal.disposables.firstObject.disposed).to.beFalsy();

    imageCellController.viewModel = viewModel;
    expect(imageSignal.disposables.firstObject.disposed).to.beTruthy();
    expect(titleSignal.disposables.firstObject.disposed).to.beTruthy();
    expect(subtitleSignal.disposables.firstObject.disposed).to.beTruthy();
    expect(durationSignal.disposables.firstObject.disposed).to.beTruthy();
  });

  it(@"should dispose subscriptions when deallocated", ^{
    __weak PTUImageCellController *weakController;

    @autoreleasepool {
      PTUImageCellController *controller = [[PTUImageCellController alloc] init];
      controller.imageSize = CGSizeMake(10, 10);
      weakController = controller;

      controller.viewModel = disposableViewModel;
      expect(imageSignal.disposables.count).to.equal(1);
      expect(titleSignal.disposables.count).to.equal(1);
      expect(subtitleSignal.disposables.count).to.equal(1);
      expect(durationSignal.disposables.count).to.equal(1);
      expect(imageSignal.disposables.firstObject.disposed).to.beFalsy();
      expect(titleSignal.disposables.firstObject.disposed).to.beFalsy();
      expect(subtitleSignal.disposables.firstObject.disposed).to.beFalsy();
      expect(durationSignal.disposables.firstObject.disposed).to.beFalsy();
    }

    expect(weakController).to.beNil();
    expect(imageSignal.disposables.firstObject.disposed).to.beTruthy();
    expect(titleSignal.disposables.firstObject.disposed).to.beTruthy();
    expect(subtitleSignal.disposables.firstObject.disposed).to.beTruthy();
    expect(durationSignal.disposables.firstObject.disposed).to.beTruthy();
  });

  it(@"should not reatin cells even if the view model signals do not complete", ^{
    __weak PTUImageCellController *weakController;

    PTUFakeImageCellViewModel *viewModel = [[PTUFakeImageCellViewModel alloc] init];
    @autoreleasepool {
      PTUImageCellController *controller = [[PTUImageCellController alloc] init];
      weakController = controller;

      controller.viewModel = viewModel;
    }

    expect(weakController).to.beNil();
  });
});

SpecEnd
