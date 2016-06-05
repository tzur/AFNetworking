// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCell.h"

#import "PTNDisposableRetainingSignal.h"
#import "PTNTestUtils.h"
#import "PTUImageCellViewModel.h"

/// \c PTUimageCellModel implementation as a value class used for testing.
@interface PTUFakeImageCellViewModel : NSObject <PTUImageCellViewModel>

/// Subject used as this view model's \c imageSignal.
@property (readonly, nonatomic) RACSubject *imageSubject;

/// Subject used as this view model's \c titleSignal.
@property (readonly, nonatomic) RACSubject *titleSubject;

/// Subject used as this view model's \c subtitleSignal.
@property (readonly, nonatomic) RACSubject *subtitleSubject;

@end

@implementation PTUFakeImageCellViewModel

- (instancetype)init {
  if (self = [super init]) {
    _imageSubject = [RACSubject subject];
    _titleSubject = [RACSubject subject];
    _subtitleSubject = [RACSubject subject];
  }
  return self;
}

- (RACSignal *)imageSignal {
  return self.imageSubject;
}

- (RACSignal *)titleSignal {
  return self.titleSubject;
}

- (RACSignal *)subtitleSignal {
  return self.subtitleSubject;
}

@end

SpecBegin(PTUimageCell)

__block PTUImageCell *imageCell;
__block PTUFakeImageCellViewModel *viewModel;
__block UIImage *image;

beforeEach(^{
  image = [[UIImage alloc] init];
  imageCell = [[PTUImageCell alloc] initWithFrame:CGRectMake(0, 0, 40, 10)];
  viewModel = [[PTUFakeImageCellViewModel alloc] init];
  imageCell.viewModel = viewModel;
});

it(@"should update image according to view model", ^{
  UIImage *otherImage = [[UIImage alloc] init];
  [viewModel.imageSubject sendNext:image];
  expect(imageCell.image).to.equal(image);
  [viewModel.imageSubject sendNext:otherImage];
  expect(imageCell.image).to.equal(otherImage);
});

it(@"should update title according to view model", ^{
  [viewModel.titleSubject sendNext:@"foo"];
  expect(imageCell.title).to.equal(@"foo");
   [viewModel.titleSubject sendNext:@"bar"];
  expect(imageCell.title).to.equal(@"bar");
});

it(@"should update subtitle according to view model", ^{
  [viewModel.subtitleSubject sendNext:@"foo"];
  expect(imageCell.subtitle).to.equal(@"foo");
  [viewModel.subtitleSubject sendNext:@"bar"];
  expect(imageCell.subtitle).to.equal(@"bar");
});

it(@"should map errors on the view model's image signal to nil", ^{
  [viewModel.imageSubject sendNext:image];
  expect(imageCell.image).to.equal(image);
  [viewModel.imageSubject sendError:[NSError lt_errorWithCode:1337]];
  expect(imageCell.image).to.beNil();
});

it(@"should map errors on the view model's title signal to nil", ^{
  [viewModel.titleSubject sendNext:@"foo"];
  expect(imageCell.title).to.equal(@"foo");
  [viewModel.titleSubject sendError:[NSError lt_errorWithCode:1337]];
  expect(imageCell.title).to.beNil();
});

it(@"should map errors on the view model's subtitle signal to nil", ^{
  [viewModel.subtitleSubject sendNext:@"foo"];
  expect(imageCell.subtitle).to.equal(@"foo");
  [viewModel.subtitleSubject sendError:[NSError lt_errorWithCode:1337]];
  expect(imageCell.subtitle).to.beNil();
});

it(@"should stop taking values from previous view model once changed", ^{
  UIImage *otherImage = [[UIImage alloc] init];
  UIImage *anotherImage = [[UIImage alloc] init];

  [viewModel.imageSubject sendNext:image];
  expect(imageCell.image).to.equal(image);

  PTUFakeImageCellViewModel *otherViewModel = [[PTUFakeImageCellViewModel alloc] init];
  imageCell.viewModel = otherViewModel;

  [otherViewModel.imageSubject sendNext:anotherImage];
  [viewModel.imageSubject sendNext:otherImage];
  expect(imageCell.image).to.equal(anotherImage);
});

it(@"should clear values when preparing to reuse", ^{
  [viewModel.titleSubject sendNext:@"foo"];
  [viewModel.subtitleSubject sendNext:@"bar"];
  [viewModel.imageSubject sendNext:image];

  expect(imageCell.title).to.equal(@"foo");
  expect(imageCell.subtitle).to.equal(@"bar");
  expect(imageCell.image).to.equal(image);

  [imageCell prepareForReuse];
  expect(imageCell.title).to.beNil();
  expect(imageCell.subtitle).to.beNil();
  expect(imageCell.image).to.beNil();
});

context(@"memory management", ^{
  __block PTNDisposableRetainingSignal *imageSignal;
  __block PTNDisposableRetainingSignal *titleSignal;
  __block PTNDisposableRetainingSignal *subtitleSignal;
  __block PTUImageCellViewModel *disposableViewModel;

  beforeEach(^{
    imageSignal = PTNCreateDisposableRetainingSignal();
    titleSignal = PTNCreateDisposableRetainingSignal();
    subtitleSignal = PTNCreateDisposableRetainingSignal();
    disposableViewModel = [[PTUImageCellViewModel alloc] initWithImageSignal:imageSignal
                                                                 titleSignal:titleSignal
                                                              subtitleSignal:subtitleSignal];
  });

  it(@"should dispose subscriptions when changing view model", ^{
    imageCell.viewModel = disposableViewModel;

    expect(imageSignal.disposables.count).to.equal(1);
    expect(titleSignal.disposables.count).to.equal(1);
    expect(subtitleSignal.disposables.count).to.equal(1);
    expect(imageSignal.disposables.firstObject.disposed).to.beFalsy();
    expect(titleSignal.disposables.firstObject.disposed).to.beFalsy();
    expect(subtitleSignal.disposables.firstObject.disposed).to.beFalsy();

    imageCell.viewModel = viewModel;
    expect(imageSignal.disposables.firstObject.disposed).to.beTruthy();
    expect(titleSignal.disposables.firstObject.disposed).to.beTruthy();
    expect(subtitleSignal.disposables.firstObject.disposed).to.beTruthy();
  });

  it(@"should dispose subscriptions when deallocated", ^{
    __weak PTUImageCell *weakCell;

    @autoreleasepool {
      PTUImageCell *cell = [[PTUImageCell alloc] initWithFrame:CGRectZero];
      weakCell = cell;

      cell.viewModel = disposableViewModel;
      expect(imageSignal.disposables.count).to.equal(1);
      expect(titleSignal.disposables.count).to.equal(1);
      expect(subtitleSignal.disposables.count).to.equal(1);
      expect(imageSignal.disposables.firstObject.disposed).to.beFalsy();
      expect(titleSignal.disposables.firstObject.disposed).to.beFalsy();
      expect(subtitleSignal.disposables.firstObject.disposed).to.beFalsy();
    }

    expect(weakCell).to.beNil();
    expect(imageSignal.disposables.firstObject.disposed).to.beTruthy();
    expect(titleSignal.disposables.firstObject.disposed).to.beTruthy();
    expect(subtitleSignal.disposables.firstObject.disposed).to.beTruthy();
  });

  it(@"should not reatin cells even if the view model signals do not complete", ^{
    __weak PTUImageCell *weakCell;

    PTUFakeImageCellViewModel *viewModel = [[PTUFakeImageCellViewModel alloc] init];
    @autoreleasepool {
      PTUImageCell *cell = [[PTUImageCell alloc] initWithFrame:CGRectZero];
      weakCell = cell;

      cell.viewModel = viewModel;
    }
    
    expect(weakCell).to.beNil();
  });
});

SpecEnd
