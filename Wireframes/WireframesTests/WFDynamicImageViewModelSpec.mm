// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFDynamicImageViewModel.h"

#import <LTKit/NSURL+Query.h>

#import "UIColor+Utilities.h"
#import "WFImageProvider.h"

SpecBegin(WFDynamicImageViewModel)

__block WFDynamicImageViewModel *viewModel;
__block id imageProvider;
__block RACSubject *imagesSignal;
__block NSURL *imageURL;
__block NSURL *highlightedImageURL;

beforeEach(^{
  imageProvider = OCMProtocolMock(@protocol(WFImageProvider));
  imageURL = [NSURL URLWithString:@"image"];
  highlightedImageURL = [NSURL URLWithString:@"highlighted"];

  imagesSignal = [RACSubject subject];

  viewModel = [[WFDynamicImageViewModel alloc] initWithImageProvider:imageProvider
                                                        imagesSignal:imagesSignal
                                                            animated:NO
                                                   animationDuration:0.5];
});

it(@"should deallocate even when images signal has not completed", ^{
  __weak WFDynamicImageViewModel *weakViewModel = nil;
  @autoreleasepool {
    WFDynamicImageViewModel *viewModel = [[WFDynamicImageViewModel alloc]
                                          initWithImageProvider:imageProvider
                                          imagesSignal:[RACSignal never] animated:NO
                                          animationDuration:0.5];
    weakViewModel = viewModel;
  }
  expect(weakViewModel).to.beNil();
});

it(@"should deallocate even when image loading has not completed", ^{
  OCMExpect([imageProvider imageWithURL:OCMOCK_ANY]).andReturn([RACSignal never]);
  RACSignal *imagesSignal = [RACSignal return:RACTuplePack([NSURL URLWithString:@"image"], nil)];

  __weak WFDynamicImageViewModel *weakViewModel = nil;
  @autoreleasepool {
    WFDynamicImageViewModel *viewModel = [[WFDynamicImageViewModel alloc]
                                          initWithImageProvider:imageProvider
                                          imagesSignal:imagesSignal animated:NO
                                          animationDuration:0.5];
    weakViewModel = viewModel;
  }

  expect(weakViewModel).to.beNil();
  OCMVerifyAll(imageProvider);
});

it(@"should fetch correct images", ^{
  UIImage *image = WFCreateBlankImage(2, 1);
  UIImage *highlightedImage = WFCreateBlankImage(2, 1);

  OCMStub([imageProvider imageWithURL:imageURL]).andReturn([RACSignal return:image]);
  OCMStub([imageProvider imageWithURL:highlightedImageURL])
      .andReturn([RACSignal return:highlightedImage]);

  [imagesSignal sendNext:RACTuplePack(imageURL, highlightedImageURL)];

  expect(viewModel.image).will.equal(image);
  expect(viewModel.highlightedImage).will.equal(highlightedImage);
});

it(@"should not fetch image when its url is nil", ^{
  UIImage *image = WFCreateBlankImage(2, 1);
  UIImage *highlightedImage = WFCreateBlankImage(2, 1);

  OCMStub([imageProvider imageWithURL:imageURL]).andReturn([RACSignal return:image]);
  OCMStub([imageProvider imageWithURL:highlightedImageURL])
      .andReturn([RACSignal return:highlightedImage]);

  [imagesSignal sendNext:RACTuplePack(nil, nil)];

  expect(viewModel.image).will.beNil();
  expect(viewModel.highlightedImage).will.beNil();
});

it(@"should not fetch highlighted image when its url is nil", ^{
  UIImage *image = WFCreateBlankImage(2, 1);
  UIImage *highlightedImage = WFCreateBlankImage(2, 1);

  OCMStub([imageProvider imageWithURL:imageURL]).andReturn([RACSignal return:image]);
  OCMStub([imageProvider imageWithURL:highlightedImageURL])
      .andReturn([RACSignal return:highlightedImage]);

  [imagesSignal sendNext:RACTuplePack(imageURL, nil)];

  expect(viewModel.image).will.equal(image);
  expect(viewModel.highlightedImage).will.beNil();
});

it(@"should update images together", ^{
  RACSubject *imageSignal = [RACSubject subject];
  OCMStub([imageProvider imageWithURL:imageURL]).andReturn(imageSignal);

  RACSubject *highlightedImageSignal = [RACSubject subject];
  OCMStub([imageProvider imageWithURL:highlightedImageURL]).andReturn(highlightedImageSignal);

  [imagesSignal sendNext:RACTuplePack(imageURL, highlightedImageURL)];

  UIImage *image = WFCreateBlankImage(2, 1);
  UIImage *highlightedImage = WFCreateBlankImage(2, 1);

  [imageSignal sendNext:image];
  [imageSignal sendCompleted];

  expect(viewModel.image).to.beNil();
  expect(viewModel.highlightedImage).to.beNil();

  [highlightedImageSignal sendNext:highlightedImage];
  [highlightedImageSignal sendCompleted];

  expect(viewModel.image).to.equal(image);
  expect(viewModel.highlightedImage).to.equal(highlightedImage);
});

it(@"should update to latest images", ^{
  UIImage *image = WFCreateBlankImage(2, 1);
  UIImage *latestImage = WFCreateBlankImage(1, 2);

  NSURL *latestURL = [NSURL URLWithString:@"latest"];
  OCMStub([imageProvider imageWithURL:imageURL]).andReturn([RACSignal return:image]);
  OCMStub([imageProvider imageWithURL:latestURL]).andReturn([RACSignal return:latestImage]);
  OCMStub([imageProvider imageWithURL:highlightedImageURL]).andReturn([RACSignal never]);

  [imagesSignal sendNext:RACTuplePack(imageURL, highlightedImageURL)];

  expect(viewModel.image).to.beNil();
  expect(viewModel.highlightedImage).to.beNil();

  [imagesSignal sendNext:RACTuplePack(latestURL, nil)];

  expect(viewModel.image).to.equal(latestImage);
  expect(viewModel.highlightedImage).to.beNil();
});

it(@"should handle errors when loading image", ^{
  RACSubject *imageSignal = [RACSubject subject];
  OCMStub([imageProvider imageWithURL:imageURL]).andReturn(imageSignal);

  RACSubject *highlightedImageSignal = [RACSubject subject];
  OCMStub([imageProvider imageWithURL:highlightedImageURL]).andReturn(highlightedImageSignal);

  [imagesSignal sendNext:RACTuplePack([NSURL URLWithString:@"image"],
                                      [NSURL URLWithString:@"highlighted"])];

  [imageSignal sendError:[NSError errorWithDomain:@"domain" code:0 userInfo:nil]];
  [highlightedImageSignal sendNext:WFCreateBlankImage(2, 1)];
  [highlightedImageSignal sendCompleted];

  expect(viewModel.image).to.beNil();
  expect(viewModel.highlightedImage).to.beNil();
});

it(@"should handle errors when loading highlighted image", ^{
  RACSubject *imageSignal = [RACSubject subject];
  OCMStub([imageProvider imageWithURL:imageURL]).andReturn(imageSignal);

  RACSubject *highlightedImageSignal = [RACSubject subject];
  OCMStub([imageProvider imageWithURL:highlightedImageURL]).andReturn(highlightedImageSignal);

  [imagesSignal sendNext:RACTuplePack([NSURL URLWithString:@"image"],
                                      [NSURL URLWithString:@"highlighted"])];

  [imageSignal sendNext:WFCreateBlankImage(2, 1)];
  [imageSignal sendCompleted];
  [highlightedImageSignal sendError:[NSError errorWithDomain:@"domain" code:0 userInfo:nil]];

  expect(viewModel.image).to.beNil();
  expect(viewModel.highlightedImage).to.beNil();
});

SpecEnd
