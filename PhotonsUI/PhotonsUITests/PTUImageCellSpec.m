// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCell.h"
#import "PTUImageCellViewModel.h"

@interface PTUFakeImageCellViewModel : NSObject <PTUImageCellViewModel>

/// Currently set title.
@property (strong, nonatomic, nullable) NSString *title;

/// Currently set subtitle.
@property (strong, nonatomic, nullable) NSString *subtitle;

/// Currently set image.
@property (strong, nonatomic, nullable) UIImage *image;

@end

@implementation PTUFakeImageCellViewModel
@end

SpecBegin(PTUImageCell)

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
  viewModel.image = image;
  expect(imageCell.image).to.equal(image);
  viewModel.image = otherImage;
  expect(imageCell.image).to.equal(otherImage);
});

it(@"should update title according to view model", ^{
  viewModel.title = @"foo";
  expect(imageCell.title).to.equal(@"foo");
  viewModel.title = @"bar";
  expect(imageCell.title).to.equal(@"bar");
});

it(@"should update subtitle according to view model", ^{
  viewModel.subtitle = @"foo";
  expect(imageCell.subtitle).to.equal(@"foo");
  viewModel.subtitle = @"bar";
  expect(imageCell.subtitle).to.equal(@"bar");
});

it(@"should stop taking values from previous view model once changed", ^{
  UIImage *otherImage = [[UIImage alloc] init];
  UIImage *anotherImage = [[UIImage alloc] init];

  viewModel.image = image;
  expect(imageCell.image).to.equal(image);

  PTUFakeImageCellViewModel *otherViewModel = [[PTUFakeImageCellViewModel alloc] init];
  imageCell.viewModel = otherViewModel;
  expect(imageCell.image).to.beNil();

  otherViewModel.image = anotherImage;
  viewModel.image = otherImage;
  expect(imageCell.image).to.equal(anotherImage);
});

it(@"should clear values when preparing for reuse", ^{
  viewModel.title = @"foo";
  viewModel.subtitle = @"bar";
  viewModel.image = image;

  expect(imageCell.title).to.equal(@"foo");
  expect(imageCell.subtitle).to.equal(@"bar");
  expect(imageCell.image).to.equal(image);

  [imageCell prepareForReuse];
  expect(imageCell.title).to.beNil();
  expect(imageCell.subtitle).to.beNil();
  expect(imageCell.image).to.beNil();
});

SpecEnd
