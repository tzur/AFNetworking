// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFImageViewModelBuilder.h"

#import "NSURL+WFImageProvider.h"
#import "UIView+LayoutSignals.h"
#import "WFDynamicImageViewModel.h"
#import "WFImageLoader.h"
#import "WFImageViewModel.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark WFImageViewModel
#pragma mark -

extern inline WFImageViewModelBuilder *WFImageViewModel(NSURL * _Nullable imageURL);

#pragma mark -
#pragma mark WFDefaultImageProvider
#pragma mark -

static inline id<WFImageProvider> WFBuiltinImageProvider() {
  static id<WFImageProvider> imageProvider;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    imageProvider = [[WFImageLoader alloc] init];
  });

  return imageProvider;
}

static id<WFImageProvider> WFDefaultImageProvider() {
  return [JSObjection defaultInjector][@protocol(WFImageProvider)] ?: WFBuiltinImageProvider();
}

#pragma mark -
#pragma mark WFImageViewModelBuilder
#pragma mark -

@interface WFImageViewModelBuilder () {
  id<WFImageProvider> _Nullable _imageProvider;
  NSURL * _Nullable _imageURL;
  NSURL * _Nullable _highlightedImageURL;
  RACSignal * _Nullable _sizeSignal;
  UIColor * _Nullable _color;
  UIColor * _Nullable _highlightedColor;
  BOOL _isBuilt;
}
@end

@implementation WFImageViewModelBuilder

+ (instancetype)builderWithImageURL:(NSURL * _Nullable)imageURL {
  return [[self alloc] initWithImageURL:imageURL];
}

- (instancetype)initWithImageURL:(NSURL * _Nullable)imageURL {
  if (self = [super init]) {
    _imageURL = imageURL;
  }
  return self;
}

- (WFImageViewModelBuilder *(^)(id<WFImageProvider>))imageProvider {
  return ^(id<WFImageProvider> imageProvider) {
    LTParameterAssert(!_isBuilt, "Builder can not be altered after the view model has already "
                      "been built");
    LTParameterAssert(!_imageProvider, @"Image provider has already been specified");
    LTParameterAssert(imageProvider);

    _imageProvider = imageProvider;
    return self;
  };
}

- (WFImageViewModelBuilder *(^)(NSURL * _Nullable))highlightedImageURL {
  return ^(NSURL * _Nullable highlightedImageURL) {
    LTParameterAssert(!_isBuilt, "Builder can not be altered after the view model has already "
                      "been built");
    LTParameterAssert(!_highlightedImageURL, "URL for highlighted image has already been "
                      "specified");
    LTParameterAssert(highlightedImageURL, "URL must not be nil. If highlighted image is not "
                      "needed, don't use this function at all");

    _highlightedImageURL = highlightedImageURL;
    return self;
  };
}

- (WFImageViewModelBuilder *(^)(CGSize))fixedSize {
  return ^(CGSize size) {
    LTParameterAssert(!_isBuilt, "Builder can not be altered after the view model has already "
                      "been built");
    LTParameterAssert(!_sizeSignal, @"Size has already been specified");
    LTParameterAssert(size.width > 0 && size.height > 0, @"Size must be positive");

    _sizeSignal = [RACSignal return:[NSValue valueWithCGSize:size]];
    return self;
  };
}

- (WFImageViewModelBuilder *(^)(RACSignal *))sizeSignal {
  return ^(RACSignal *sizeSignal) {
    LTParameterAssert(!_isBuilt, "Builder can not be altered after the view model has already "
                      "been built");
    LTParameterAssert(!_sizeSignal, @"Size has already been specified");
    LTParameterAssert(sizeSignal);

    _sizeSignal = [[sizeSignal
        filter:^BOOL(NSValue *value) {
          CGSize size = [value CGSizeValue];
          return size.width > 0 && size.height > 0;
        }]
        distinctUntilChanged];

    return self;
  };
}

- (WFImageViewModelBuilder *(^)(UIView *))sizeToBounds {
  return ^(UIView *view) {
    LTParameterAssert(!_isBuilt, "Builder can not be altered after the view model has already "
                      "been built");
    LTParameterAssert(!_sizeSignal, @"Size has already been specified");
    LTParameterAssert(view);

    _sizeSignal = view.wf_positiveSizeSignal;
    return self;
  };
}

- (WFImageViewModelBuilder *(^)(UIColor *))color {
  return ^(UIColor *color) {
    LTParameterAssert(!_isBuilt, "Builder can not be altered after the view model has already "
                      "been built");
    LTParameterAssert(!_color, @"Color has already been specified");

    _color = color;
    return self;
  };
}

- (WFImageViewModelBuilder *(^)(UIColor *))highlightedColor {
  return ^(UIColor *highlightedColor) {
    LTParameterAssert(!_isBuilt, "Builder can not be altered after the view model has already "
                      "been built");
    LTParameterAssert(!_highlightedColor, @"Highlighted color has already been specified");

    _highlightedColor = highlightedColor;
    return self;
  };
}

- (id<WFImageViewModel> (^)())build {
  return ^{
    LTParameterAssert(!_isBuilt, @"build() can be called only once, and it has already been "
                      "called");

    _isBuilt = YES;

    RACSignal *imagesSignal =
        [RACSignal return:RACTuplePack([self transformedImageURL],
                                       [self transformedHighlightedImageURL])];
    if (_sizeSignal) {
      imagesSignal = [RACSignal
          combineLatest:@[imagesSignal, _sizeSignal]
          reduce:^RACTuple *(RACTuple *images, NSValue *sizeValue) {
            RACTupleUnpack(NSURL * _Nullable imageURL,
                           NSURL * _Nullable highlightedImageURL) = images;
            CGSize size = [sizeValue CGSizeValue];
            return RACTuplePack([imageURL wf_URLWithImageSize:size],
                                [highlightedImageURL wf_URLWithImageSize:size]);
          }];
    }

    id<WFImageProvider> imageProvider = _imageProvider ?: WFDefaultImageProvider();
    return [[WFDynamicImageViewModel alloc] initWithImageProvider:imageProvider
                                                     imagesSignal:imagesSignal];
  };
}

- (nullable NSURL *)transformedImageURL {
  return _color ? [_imageURL wf_URLWithImageColor:_color] : _imageURL;
}

- (nullable NSURL *)transformedHighlightedImageURL {
  if (!_highlightedColor) {
    return _highlightedImageURL;
  } else {
    if (_highlightedImageURL) {
      return [_highlightedImageURL wf_URLWithImageColor:_highlightedColor];
    } else {
      return [_imageURL wf_URLWithImageColor:_highlightedColor];
    }
  }
}

@end

NS_ASSUME_NONNULL_END
