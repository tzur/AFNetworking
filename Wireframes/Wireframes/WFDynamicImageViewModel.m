// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFDynamicImageViewModel.h"

#import "NSURL+WFImageProvider.h"
#import "WFImageProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFDynamicImageViewModel ()

/// Image to display. If \c nil, no image is displayed.
@property (readwrite, nonatomic, nullable) UIImage *image;

/// Image to display when in highlighted state. If \c nil, \c image is used instead.
@property (readwrite, nonatomic, nullable) UIImage *highlightedImage;

@end

@implementation WFDynamicImageViewModel

@synthesize isAnimated = _isAnimated;
@synthesize animationDuration = _animationDuration;

- (instancetype)initWithImageProvider:(id<WFImageProvider>)imageProvider
                         imagesSignal:(RACSignal<RACTwoTuple<NSURL *, NSURL *> *> *)imagesSignal
                             animated:(BOOL)animated
                    animationDuration:(NSTimeInterval)animationDuration {
  if (self = [super init]) {
    _isAnimated = animated;
    _animationDuration = animationDuration;

    @weakify(self);
    [[[[[[[imagesSignal
        takeUntil:self.rac_willDeallocSignal]
        map:^RACTuple *(RACTuple *value) {
          LTParameterAssert([value isKindOfClass:RACTuple.class], @"Signal must carry only "
                            "RACTuple instances, got %@ instead", value.class);
          LTParameterAssert(value.count == 2, @"Signal must carry only RACTuple instances with "
                            "exactly 2 items, got %lu instead", (unsigned long)value.count);

          RACTupleUnpack(NSURL * _Nullable imageURL, NSURL * _Nullable highlightedImageURL) = value;
          LTParameterAssert(!imageURL || [imageURL isKindOfClass:NSURL.class], @"Signal must carry "
                            "only tuples with NSURL instances for image URLs, got %@ instead",
                            imageURL.class);
          LTParameterAssert(!highlightedImageURL || [highlightedImageURL isKindOfClass:NSURL.class],
                            @"Signal must carry only tuples with NSURL instances for highlighted "
                            "image URLs, got %@ instead", highlightedImageURL.class);

          if ([imageURL isEqual:highlightedImageURL]) {
            // Image view model protocol states that image is used instead of highlightedImage when
            // the latter is nil. Thus when both image URLs are equal, there is not need to load
            // them twice.
            highlightedImageURL = nil;
          }
          return RACTuplePack(imageURL, highlightedImageURL);
        }]
        distinctUntilChanged]
        map:^RACStream *(RACTuple *value) {
          RACTupleUnpack(NSURL * _Nullable imageURL, NSURL * _Nullable highlightedImageURL) = value;

          RACSignal *image = imageURL ?
              [imageProvider imageWithURL:imageURL] : [RACSignal return:nil];
          RACSignal *highlightedImage = highlightedImageURL ?
              [imageProvider imageWithURL:highlightedImageURL] : [RACSignal return:nil];

          return [RACSignal zip:@[
            [image deliverOnMainThread],
            [highlightedImage deliverOnMainThread]
          ]];
        }]
        deliverOnMainThread]
        switchToLatest]
        subscribeNext:^(RACTuple *value) {
          @strongify(self);
          RACTupleUnpack(UIImage * _Nullable image, UIImage * _Nullable highlightedImage) = value;
          self.image = image;
          self.highlightedImage = highlightedImage;
        } error:^(NSError *error) {
          @strongify(self);
          LogError(@"%@: Error loading image: %@", self, error.description);
          self.image = nil;
          self.highlightedImage = nil;
        }];
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
