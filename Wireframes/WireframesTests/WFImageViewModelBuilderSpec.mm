// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFImageViewModelBuilder.h"

#import <LTKit/NSURL+Query.h>
#import <LTKit/UIColor+Utilities.h>

#import "WFImageProvider.h"
#import "WFImageViewModel.h"

extern "C" id<WFImageProvider> WFDefaultImageProvider() {
  LTAssert(NO, "Default image provider should not be used");
  return nil;
}

SpecBegin(WFImageViewModelBuilder)

__block id imageProvider;

beforeEach(^{
  imageProvider = OCMProtocolMock(@protocol(WFImageProvider));
});

it(@"should build view model with no image when nil URL is given", ^{
  id<WFImageViewModel> viewModel = [WFImageViewModelBuilder builderWithImageURL:nil]
      .imageProvider(imageProvider)
      .build();

  expect(viewModel.image).to.beNil();
  expect(viewModel.highlightedImage).to.beNil();
});

it(@"should build view model with image and no size", ^{
  NSURL *imageURL = [NSURL URLWithString:@"image"];
  UIImage *image = WFCreateBlankImage(1, 1);

  OCMExpect([imageProvider imageWithURL:imageURL]).andReturn([RACSignal return:image]);

  id<WFImageViewModel> viewModel = [WFImageViewModelBuilder builderWithImageURL:imageURL]
      .imageProvider(imageProvider)
      .build();

  OCMVerifyAll(imageProvider);

  expect(viewModel.image).to.equal(image);
  expect(viewModel.highlightedImage).to.beNil();
});

it(@"should build view model with highlighted image and no size", ^{
  NSURL *imageURL = [NSURL URLWithString:@"image"];
  NSURL *highlightedImageURL = [NSURL URLWithString:@"highlighted"];
  UIImage *image = WFCreateBlankImage(1, 1);
  UIImage *highlightedImage = WFCreateBlankImage(1, 1);

  OCMExpect([imageProvider imageWithURL:imageURL]).andReturn([RACSignal return:image]);
  OCMExpect([imageProvider imageWithURL:highlightedImageURL])
      .andReturn([RACSignal return:highlightedImage]);

  id<WFImageViewModel> viewModel = [WFImageViewModelBuilder builderWithImageURL:imageURL]
      .highlightedImageURL(highlightedImageURL)
      .imageProvider(imageProvider)
      .build();

  OCMVerifyAll(imageProvider);

  expect(viewModel.image).to.equal(image);
  expect(viewModel.highlightedImage).to.equal(highlightedImage);
});

it(@"should build view model with highlighted image and fixed size", ^{
  NSURL *imageURL = [NSURL URLWithString:@"image"];
  NSURL *highlightedImageURL = [NSURL URLWithString:@"highlighted"];
  UIImage *image = WFCreateBlankImage(1, 1);
  UIImage *highlightedImage = WFCreateBlankImage(1, 1);

  OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
    return [url.path isEqualToString:@"image"] &&
        [url.lt_queryDictionary[@"width"] isEqualToString:@"2"] &&
        [url.lt_queryDictionary[@"height"] isEqualToString:@"1"];
  }]]).andReturn([RACSignal return:image]);

  OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
    return [url.path isEqualToString:@"highlighted"] &&
      [url.lt_queryDictionary[@"width"] isEqualToString:@"2"] &&
      [url.lt_queryDictionary[@"height"] isEqualToString:@"1"];
  }]]).andReturn([RACSignal return:highlightedImage]);

  id<WFImageViewModel> viewModel =
      [WFImageViewModelBuilder builderWithImageURL:imageURL]
          .highlightedImageURL(highlightedImageURL)
          .fixedSize(CGSizeMake(2, 1))
          .imageProvider(imageProvider)
          .build();

  OCMVerifyAll(imageProvider);

  expect(viewModel.image).to.equal(image);
  expect(viewModel.highlightedImage).to.equal(highlightedImage);
});

it(@"should build view model with image and defined line width", ^{
  NSURL *imageURL = [NSURL URLWithString:@"image"];
  NSURL *highlightedImageURL = [NSURL URLWithString:@"highlighted"];
  UIImage *image = WFCreateBlankImage(1, 1);
  UIImage *highlightedImage = WFCreateBlankImage(1, 1);

  OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
    return [url.path isEqualToString:@"image"] &&
        [url.lt_queryDictionary[@"lineWidth"] isEqualToString:@"1.5"];
  }]]).andReturn([RACSignal return:image]);

  OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
    return [url.path isEqualToString:@"highlighted"] &&
    [url.lt_queryDictionary[@"lineWidth"] isEqualToString:@"1.5"];
  }]]).andReturn([RACSignal return:highlightedImage]);

  id<WFImageViewModel> viewModel =
      [WFImageViewModelBuilder builderWithImageURL:imageURL]
          .highlightedImageURL(highlightedImageURL)
          .lineWidth(1.5)
          .imageProvider(imageProvider)
          .build();

  OCMVerifyAll(imageProvider);

  expect(viewModel.image).to.equal(image);
  expect(viewModel.highlightedImage).to.equal(highlightedImage);
});

context(@"size of view bounds", ^{
  __block UIView *view;

  beforeEach(^{
    view = [[UIView alloc] initWithFrame:CGRectZero];
  });

  it(@"should build view model with image and size of initial view bounds", ^{
    NSURL *imageURL = [NSURL URLWithString:@"image"];
    UIImage *image = WFCreateBlankImage(1, 1);

    view.bounds = CGRectMake(0, 0, 2, 1);

    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      return [url.path isEqualToString:@"image"] &&
          [url.lt_queryDictionary[@"width"] isEqualToString:@"2"] &&
          [url.lt_queryDictionary[@"height"] isEqualToString:@"1"];
    }]]).andReturn([RACSignal return:image]);

    id<WFImageViewModel> viewModel =
        [WFImageViewModelBuilder builderWithImageURL:imageURL]
            .sizeToBounds(view)
            .imageProvider(imageProvider)
            .build();

    OCMVerifyAll(imageProvider);

    expect(viewModel.image).to.equal(image);
    expect(viewModel.highlightedImage).to.beNil();
  });

  it(@"should reload image when view bounds change", ^{
    NSURL *imageURL = [NSURL URLWithString:@"image"];
    UIImage *image1 = WFCreateBlankImage(1, 2);
    UIImage *image2 = WFCreateBlankImage(3, 4);

    view.bounds = CGRectMake(0, 0, 1, 2);

    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      return [url.path isEqualToString:@"image"] &&
          [url.lt_queryDictionary[@"width"] isEqualToString:@"1"] &&
          [url.lt_queryDictionary[@"height"] isEqualToString:@"2"];
    }]]).andReturn([RACSignal return:image1]);

    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      return [url.path isEqualToString:@"image"] &&
          [url.lt_queryDictionary[@"width"] isEqualToString:@"3"] &&
          [url.lt_queryDictionary[@"height"] isEqualToString:@"4"];
    }]]).andReturn([RACSignal return:image2]);

    id<WFImageViewModel> viewModel = [WFImageViewModelBuilder builderWithImageURL:imageURL]
        .sizeToBounds(view)
        .imageProvider(imageProvider)
        .build();

    expect(viewModel.image).to.equal(image1);

    view.bounds = CGRectMake(0, 0, 3, 4);
    [view layoutIfNeeded];

    expect(viewModel.image).to.equal(image2);

    OCMVerifyAll(imageProvider);
  });

  it(@"should not prevent view deallocation", ^{
    OCMStub([imageProvider imageWithURL:OCMOCK_ANY]).andReturn([RACSignal never]);

    __weak UIView *weakView = nil;
    id<WFImageViewModel> viewModel = nil;

    @autoreleasepool {
      UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 1)];
      weakView = view;

      viewModel = [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@"image"]]
          .sizeToBounds(view)
          .imageProvider(imageProvider)
          .build();
    }

    expect(weakView).to.beNil();
  });
});

context(@"size signal", ^{
  __block RACSubject *sizeSignal;
  __block id<WFImageViewModel> viewModel;

  beforeEach(^{
    sizeSignal = [RACSubject subject];

    viewModel = [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@"image"]]
        .sizeSignal(sizeSignal)
        .imageProvider(imageProvider)
        .build();
  });

  it(@"should not load images before size is sent", ^{
    expect(viewModel.image).to.beNil();
    expect(viewModel.highlightedImage).to.beNil();
  });

  it(@"should load image with correct size", ^{
    UIImage *image = WFCreateBlankImage(1, 1);
    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      return [url.path isEqualToString:@"image"] &&
        [url.lt_queryDictionary[@"width"] isEqualToString:@"2"] &&
        [url.lt_queryDictionary[@"height"] isEqualToString:@"1"];
    }]]).andReturn([RACSignal return:image]);

    [sizeSignal sendNext:$(CGSizeMake(2, 1))];

    OCMVerifyAll(imageProvider);
    expect(viewModel.image).to.equal(image);
  });

  it(@"should switch to latest size", ^{
    UIImage *image = WFCreateBlankImage(1, 2);

    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      return [url.path isEqualToString:@"image"] &&
          [url.lt_queryDictionary[@"width"] isEqualToString:@"1"] &&
          [url.lt_queryDictionary[@"height"] isEqualToString:@"1"];
    }]]).andReturn([RACSignal never]);

    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      return [url.path isEqualToString:@"image"] &&
          [url.lt_queryDictionary[@"width"] isEqualToString:@"1"] &&
          [url.lt_queryDictionary[@"height"] isEqualToString:@"2"];
    }]]).andReturn([RACSignal return:image]);

    [sizeSignal sendNext:$(CGSizeMake(1, 1))];
    [sizeSignal sendNext:$(CGSizeMake(1, 2))];

    OCMVerifyAll(imageProvider);
    expect(viewModel.image).to.equal(image);
  });

  it(@"should not prevent deallocation when size signal does not complete", ^{
    __weak id<WFImageViewModel> weakViewModel = nil;
    @autoreleasepool {
      id<WFImageViewModel> viewModel =
          [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@"image"]]
              .sizeSignal([RACSignal never])
              .imageProvider(imageProvider)
              .build();
      weakViewModel = viewModel;
    }
    expect(weakViewModel).to.beNil();
  });
});

context(@"color", ^{
  it(@"should pass color to image provider", ^{
    UIColor *expectedColor = [UIColor lt_colorWithHex:@"#12345678"];

    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      UIColor *color = [UIColor lt_colorWithHex:url.lt_queryDictionary[@"color"]];
      return [url.path isEqualToString:@"image"] && [expectedColor isEqual:color];
    }]]).andReturn([RACSignal never]);

    id<WFImageViewModel> __unused viewModel =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@"image"]]
            .imageProvider(imageProvider)
            .color(expectedColor)
            .build();

    OCMVerifyAll(imageProvider);
  });

  it(@"should pass highlighted color to image provider", ^{
    UIColor *expectedColor = [UIColor lt_colorWithHex:@"#12345678"];
    UIColor *expectedHighlightedColor = [UIColor lt_colorWithHex:@"#87654321"];

    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      UIColor *color = [UIColor lt_colorWithHex:url.lt_queryDictionary[@"color"]];
      return [url.path isEqualToString:@"image"] && [expectedColor isEqual:color];
    }]]).andReturn([RACSignal never]);

    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      UIColor *color = [UIColor lt_colorWithHex:url.lt_queryDictionary[@"color"]];
      return [url.path isEqualToString:@"highlighted"] && [expectedHighlightedColor isEqual:color];
    }]]).andReturn([RACSignal never]);

    id<WFImageViewModel> __unused viewModel =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@"image"]]
            .highlightedImageURL([NSURL URLWithString:@"highlighted"])
            .imageProvider(imageProvider)
            .color(expectedColor)
            .highlightedColor(expectedHighlightedColor)
            .build();

    OCMVerifyAll(imageProvider);
  });

  it(@"should use image url with highlighted color", ^{
    UIColor *expectedColor = [UIColor lt_colorWithHex:@"#12345678"];
    UIColor *expectedHighlightedColor = [UIColor lt_colorWithHex:@"#87654321"];

    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      UIColor *color = [UIColor lt_colorWithHex:url.lt_queryDictionary[@"color"]];
      return [url.path isEqualToString:@"image"] && [expectedColor isEqual:color];
    }]]).andReturn([RACSignal never]);

    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      UIColor *color = [UIColor lt_colorWithHex:url.lt_queryDictionary[@"color"]];
      return [url.path isEqualToString:@"image"] && [expectedHighlightedColor isEqual:color];
    }]]).andReturn([RACSignal never]);

    id<WFImageViewModel> __unused viewModel =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@"image"]]
            .imageProvider(imageProvider)
            .color(expectedColor)
            .highlightedColor(expectedHighlightedColor)
            .build();

    OCMVerifyAll(imageProvider);
  });
});

context(@"line width", ^{
  it(@"should pass line width to image provider and highlighted image provider", ^{
    CGFloat expectedLineWidth = 1.4;

    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      CGFloat lineWidth = [url.lt_queryDictionary[@"lineWidth"] floatValue];
      return [url.path isEqualToString:@"image"] && std::abs(expectedLineWidth - lineWidth) < 0.001;
    }]]).andReturn([RACSignal never]);

    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      CGFloat lineWidth = [url.lt_queryDictionary[@"lineWidth"] floatValue];
      return [url.path isEqualToString:@"highlighted"] &&
          std::abs(expectedLineWidth - lineWidth) < 0.001;
    }]]).andReturn([RACSignal never]);

    id<WFImageViewModel> __unused viewModel =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@"image"]]
            .highlightedImageURL([NSURL URLWithString:@"highlighted"])
            .imageProvider(imageProvider)
            .lineWidth(expectedLineWidth)
            .build();

    OCMVerifyAll(imageProvider);
  });

  it(@"should pass line width to colored image provider and highlighted image provider", ^{
    CGFloat expectedLineWidth = 1.4;
    UIColor *expectedColor = [UIColor lt_colorWithHex:@"#12345678"];
    UIColor *expectedHighlightedColor = [UIColor lt_colorWithHex:@"#87654321"];

    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      CGFloat lineWidth = [url.lt_queryDictionary[@"lineWidth"] floatValue];
      UIColor *color = [UIColor lt_colorWithHex:url.lt_queryDictionary[@"color"]];

      return [url.path isEqualToString:@"image"] &&
          std::abs(expectedLineWidth - lineWidth) < 0.001 &&
          [expectedColor isEqual:color];
    }]]).andReturn([RACSignal never]);

    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      CGFloat lineWidth = [url.lt_queryDictionary[@"lineWidth"] floatValue];
      UIColor *color = [UIColor lt_colorWithHex:url.lt_queryDictionary[@"color"]];

      return [url.path isEqualToString:@"highlighted"] &&
          std::abs(expectedLineWidth - lineWidth) < 0.001 &&
          [expectedHighlightedColor isEqual:color];
    }]]).andReturn([RACSignal never]);

    id<WFImageViewModel> __unused viewModel =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@"image"]]
            .highlightedImageURL([NSURL URLWithString:@"highlighted"])
            .imageProvider(imageProvider)
            .lineWidth(expectedLineWidth)
            .color(expectedColor)
            .highlightedColor(expectedHighlightedColor)
            .build();

    OCMVerifyAll(imageProvider);
  });

  it(@"should pass line width to colored image provider and inexplicitly set highlighted image "
     "provider", ^{
    CGFloat expectedLineWidth = 1.4;
    UIColor *expectedColor = [UIColor lt_colorWithHex:@"#12345678"];
    UIColor *expectedHighlightedColor = [UIColor lt_colorWithHex:@"#87654321"];

    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      CGFloat lineWidth = [url.lt_queryDictionary[@"lineWidth"] floatValue];
      UIColor *color = [UIColor lt_colorWithHex:url.lt_queryDictionary[@"color"]];

      return [url.path isEqualToString:@"image"] &&
          std::abs(expectedLineWidth - lineWidth) < 0.001 &&
          [expectedColor isEqual:color];
    }]]).andReturn([RACSignal never]);

    OCMExpect([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
      CGFloat lineWidth = [url.lt_queryDictionary[@"lineWidth"] floatValue];
      UIColor *color = [UIColor lt_colorWithHex:url.lt_queryDictionary[@"color"]];
      return [url.path isEqualToString:@"image"] &&
          std::abs(expectedLineWidth - lineWidth) < 0.001 &&
          [expectedHighlightedColor isEqual:color];
    }]]).andReturn([RACSignal never]);

    id<WFImageViewModel> __unused viewModel =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@"image"]]
            .imageProvider(imageProvider)
            .lineWidth(expectedLineWidth)
            .color(expectedColor)
            .highlightedColor(expectedHighlightedColor)
            .build();

    OCMVerifyAll(imageProvider);
  });
});

context(@"animation", ^{
  it(@"should pass animate flag to view model", ^{
    id<WFImageViewModel> viewModel =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@"image"]]
            .animated(YES)
            .build();

    expect(viewModel.isAnimated).to.beTruthy();
  });

  it(@"should return view model by defaulting isAnimated to NO", ^{
    id<WFImageViewModel> viewModel =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@"image"]]
            .build();

    expect(viewModel.isAnimated).to.beFalsy();
  });

  it(@"should use latest animated value", ^{
    id<WFImageViewModel> viewModel =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@"image"]]
            .animated(YES)
            .animated(YES)
            .animated(NO)
            .build();

    expect(viewModel.isAnimated).to.beFalsy();
  });

  it(@"should pass animationDuration to view model", ^{
    id<WFImageViewModel> viewModel =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@"image"]]
            .animationDuration(0.7)
            .build();

    expect(viewModel.animationDuration).to.equal(0.7);
  });

  it(@"should return view model by defaulting animationDuration to 0.25", ^{
    id<WFImageViewModel> viewModel =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@"image"]]
            .build();

    expect(viewModel.animationDuration).to.equal(0.25);
  });

  it(@"should use latest animationDuration value", ^{
    id<WFImageViewModel> viewModel =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@"image"]]
            .animationDuration(0.7)
            .animationDuration(0.5)
            .build();

    expect(viewModel.animationDuration).to.equal(0.5);
  });
});

context(@"errors", ^{
  it(@"should raise if built twice", ^{
    OCMStub([imageProvider imageWithURL:OCMOCK_ANY]).andReturn([RACSignal never]);

    WFImageViewModelBuilder *builder =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@""]]
            .imageProvider(imageProvider);

    expect(builder.build()).toNot.beNil();
    expect(^{
      builder.build();
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if highlighted image url is set twice", ^{
    WFImageViewModelBuilder *builder =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@""]]
            .imageProvider(imageProvider)
            .highlightedImageURL([NSURL URLWithString:@""]);

    expect(^{
      builder.highlightedImageURL([NSURL URLWithString:@""]);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if non-positive size is set", ^{
    WFImageViewModelBuilder *builder =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@""]]
            .imageProvider(imageProvider);

    expect(^{
      builder.fixedSize(CGSizeMake(0, 1));
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      builder.fixedSize(CGSizeMake(1, 0));
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      builder.fixedSize(CGSizeMake(-1, -1));
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if size is set twice", ^{
    WFImageViewModelBuilder *builder =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@""]]
            .imageProvider(imageProvider)
            .fixedSize(CGSizeMake(1, 1));

    expect(^{
      builder.fixedSize(CGSizeMake(2, 2));
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      builder.sizeToBounds([[UIView alloc] initWithFrame:CGRectZero]);
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      builder.sizeSignal([RACSignal never]);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if color is set twice", ^{
    WFImageViewModelBuilder *builder =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@""]]
            .imageProvider(imageProvider)
            .color([UIColor whiteColor]);

    expect(^{
      builder.color([UIColor whiteColor]);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if highlighted color is set twice", ^{
    WFImageViewModelBuilder *builder =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@""]]
            .imageProvider(imageProvider)
            .highlightedColor([UIColor whiteColor]);

    expect(^{
      builder.highlightedColor([UIColor whiteColor]);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if non-positive line width is set", ^{
    WFImageViewModelBuilder *builder =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@""]]
            .imageProvider(imageProvider);

    expect(^{
      builder.lineWidth(0);
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      builder.lineWidth(-1.3);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if line width is set twice", ^{
    WFImageViewModelBuilder *builder =
        [WFImageViewModelBuilder builderWithImageURL:[NSURL URLWithString:@""]]
            .imageProvider(imageProvider)
            .lineWidth(1.4);

    expect(^{
      builder.lineWidth(3.2);
    }).to.raise(NSInvalidArgumentException);
  });
});

SpecEnd
