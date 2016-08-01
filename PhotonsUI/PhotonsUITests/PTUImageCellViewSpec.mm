// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellView.h"

#import "PTNDisposableRetainingSignal.h"
#import "PTNTestUtils.h"
#import "PTUImageCellViewModel.h"

/// \c PTUimageCellModel implementation using subjects as the view models signals used for testing.
@interface PTUFakeImageCellViewModel : NSObject <PTUImageCellViewModel>

/// Initializes with \c imageSignal to be returned by \c imageSignalForCellSize: with any parameter,
/// \c titleSignal and \c subtitleSignal.
- (instancetype)initWithImageSignal:(nullable RACSignal *)imageSignal
                        titleSignal:(nullable RACSignal *)titleSignal
                     subtitleSignal:(nullable RACSignal *)subtitleSignal;

/// Signal used as this view model's \c imageSignalForCellSize: with any size.
@property (strong, nonatomic) RACSignal *imageSignal;

/// Signal used as this view model's \c titleSignal.
@property (strong, nonatomic) RACSignal *titleSignal;

/// Signal used as this view model's \c subtitleSignal.
@property (strong, nonatomic) RACSignal *subtitleSignal;

@end

@implementation PTUFakeImageCellViewModel

- (instancetype)initWithImageSignal:(RACSignal *)imageSignal titleSignal:(RACSignal *)titleSignal
                     subtitleSignal:(RACSignal *)subtitleSignal {
  if (self = [super init]) {
    _imageSignal = imageSignal;
    _titleSignal = titleSignal;
    _subtitleSignal = subtitleSignal;
  }
  return self;
}

- (RACSignal *)imageSignalForCellSize:(CGSize __unused)cellSize {
  return self.imageSignal;
}

@end

SpecBegin(PTUImageCellView)

__block PTUImageCellView *imageCellView;
__block PTUFakeImageCellViewModel *viewModel;
__block UIImage *image;
__block RACSubject *imageSubject;
__block RACSubject *titleSubject;
__block RACSubject *subtitleSubject;

beforeEach(^{
  image = [[UIImage alloc] init];
  imageCellView = [[PTUImageCellView alloc] initWithFrame:CGRectMake(0, 0, 40, 10)];
  [imageCellView layoutIfNeeded];
  imageSubject = [RACSubject subject];
  titleSubject = [RACSubject subject];
  subtitleSubject = [RACSubject subject];
  viewModel = [[PTUFakeImageCellViewModel alloc] initWithImageSignal:imageSubject
                                                         titleSignal:titleSubject
                                                      subtitleSignal:subtitleSubject];
  imageCellView.viewModel = viewModel;
});

it(@"should not fetch images before initial layout", ^{
  PTUImageCellView *cellView = [[PTUImageCellView alloc] initWithFrame:CGRectMake(0, 0, 40, 10)];
  cellView.viewModel = viewModel;
  
  [imageSubject sendNext:image];
  expect(cellView.image).to.beNil();

  [cellView layoutIfNeeded];
  [imageSubject sendNext:image];
  expect(cellView.image).to.equal(image);
});

it(@"should update image according to view model", ^{
  UIImage *otherImage = [[UIImage alloc] init];
  [imageSubject sendNext:image];
  expect(imageCellView.image).to.equal(image);
  [imageSubject sendNext:otherImage];
  expect(imageCellView.image).to.equal(otherImage);
});

it(@"should update image when view size changes", ^{
  CGFloat scale = imageCellView.contentScaleFactor;
  id<PTUImageCellViewModel> viewModel = OCMProtocolMock(@protocol(PTUImageCellViewModel));
  imageCellView.viewModel = viewModel;
  OCMVerify([viewModel imageSignalForCellSize:CGSizeMake(40 * scale, 10 * scale)]);

  [imageCellView setFrame:CGRectMake(0, 0, 100, 100)];
  [imageCellView layoutIfNeeded];
  OCMVerify([viewModel imageSignalForCellSize:CGSizeMake(100 * scale, 100 * scale)]);
});

it(@"should update title according to view model", ^{
  [titleSubject sendNext:@"foo"];
  expect(imageCellView.title).to.equal(@"foo");
   [titleSubject sendNext:@"bar"];
  expect(imageCellView.title).to.equal(@"bar");
});

it(@"should update subtitle according to view model", ^{
  [subtitleSubject sendNext:@"foo"];
  expect(imageCellView.subtitle).to.equal(@"foo");
  [subtitleSubject sendNext:@"bar"];
  expect(imageCellView.subtitle).to.equal(@"bar");
});

it(@"should map errors on the view model's image signal to nil", ^{
  [imageSubject sendNext:image];
  expect(imageCellView.image).to.equal(image);
  [imageSubject sendError:[NSError lt_errorWithCode:1337]];
  expect(imageCellView.image).to.beNil();
});

it(@"should map errors on the view model's title signal to nil", ^{
  [titleSubject sendNext:@"foo"];
  expect(imageCellView.title).to.equal(@"foo");
  [titleSubject sendError:[NSError lt_errorWithCode:1337]];
  expect(imageCellView.title).to.beNil();
});

it(@"should map errors on the view model's subtitle signal to nil", ^{
  [subtitleSubject sendNext:@"foo"];
  expect(imageCellView.subtitle).to.equal(@"foo");
  [subtitleSubject sendError:[NSError lt_errorWithCode:1337]];
  expect(imageCellView.subtitle).to.beNil();
});

it(@"should stop taking values from previous view model once changed", ^{
  UIImage *otherImage = [[UIImage alloc] init];
  UIImage *anotherImage = [[UIImage alloc] init];

  [imageSubject sendNext:image];
  expect(imageCellView.image).to.equal(image);

  RACSubject *newSubject = [RACSubject subject];
  PTUFakeImageCellViewModel *otherViewModel =
      [[PTUFakeImageCellViewModel alloc] initWithImageSignal:newSubject titleSignal:nil
                                              subtitleSignal:nil];
  imageCellView.viewModel = otherViewModel;

  [newSubject sendNext:otherImage];
  [imageSubject sendNext:anotherImage];
  expect(imageCellView.image).to.equal(otherImage);
});

it(@"should clear values when setting a new view model", ^{
  [titleSubject sendNext:@"foo"];
  [subtitleSubject sendNext:@"bar"];
  [imageSubject sendNext:image];

  expect(imageCellView.title).to.equal(@"foo");
  expect(imageCellView.subtitle).to.equal(@"bar");
  expect(imageCellView.image).to.equal(image);

  imageCellView.viewModel = nil;
  expect(imageCellView.title).to.beNil();
  expect(imageCellView.subtitle).to.beNil();
  expect(imageCellView.image).to.beNil();
});

context(@"memory management", ^{
  __block PTNDisposableRetainingSignal *imageSignal;
  __block PTNDisposableRetainingSignal *titleSignal;
  __block PTNDisposableRetainingSignal *subtitleSignal;
  __block PTUFakeImageCellViewModel *disposableViewModel;

  beforeEach(^{
    imageSignal = PTNCreateDisposableRetainingSignal();
    titleSignal = PTNCreateDisposableRetainingSignal();
    subtitleSignal = PTNCreateDisposableRetainingSignal();
    disposableViewModel = [[PTUFakeImageCellViewModel alloc] initWithImageSignal:imageSignal
                                                                     titleSignal:titleSignal
                                                                  subtitleSignal:subtitleSignal];
  });

  it(@"should dispose subscriptions when changing view model", ^{
    imageCellView.viewModel = disposableViewModel;

    expect(imageSignal.disposables.count).to.equal(1);
    expect(titleSignal.disposables.count).to.equal(1);
    expect(subtitleSignal.disposables.count).to.equal(1);
    expect(imageSignal.disposables.firstObject.disposed).to.beFalsy();
    expect(titleSignal.disposables.firstObject.disposed).to.beFalsy();
    expect(subtitleSignal.disposables.firstObject.disposed).to.beFalsy();

    imageCellView.viewModel = viewModel;
    expect(imageSignal.disposables.firstObject.disposed).to.beTruthy();
    expect(titleSignal.disposables.firstObject.disposed).to.beTruthy();
    expect(subtitleSignal.disposables.firstObject.disposed).to.beTruthy();
  });

  it(@"should dispose subscriptions when deallocated", ^{
    __weak PTUImageCellView *weakCell;

    @autoreleasepool {
      PTUImageCellView *cell = [[PTUImageCellView alloc] initWithFrame:CGRectMake(0, 0, 40, 10)];
      [cell layoutIfNeeded];
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
    __weak PTUImageCellView *weakCell;

    PTUFakeImageCellViewModel *viewModel = [[PTUFakeImageCellViewModel alloc] init];
    @autoreleasepool {
      PTUImageCellView *cell = [[PTUImageCellView alloc] initWithFrame:CGRectZero];
      weakCell = cell;

      cell.viewModel = viewModel;
    }

    expect(weakCell).to.beNil();
  });
});

SpecEnd
