// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMFormatStrategy.h"

#import <AVFoundation/AVFoundation.h>

static AVCaptureDeviceFormat *CAMAVCaptureDeviceFormatMock(FourCharCode subtype,
                                                           int32_t width,
                                                           int32_t height) {
  CMVideoFormatDescriptionRef description;
  CMVideoFormatDescriptionCreate(NULL, subtype, width, height, NULL, &description);
  id format = OCMClassMock([AVCaptureDeviceFormat class]);
  OCMStub([format formatDescription]).andReturn(description);
  return format;
}

SpecBegin(CAMFormatStrategy)

context(@"factory", ^{
  static const NSUInteger kWidth = 300;
  static const NSUInteger kHeight = 250;

  it(@"should return highest res strategy", ^{
    expect([CAMFormatStrategy highestResolution420f]).to.
        beKindOf([CAMFormatStrategyHighestResolution420f class]);
  });

  it(@"should return exact res strategy", ^{
    CAMFormatStrategyExactResolution420f *strategy =
        [CAMFormatStrategy exact420fWidth:kWidth height:kHeight];

    expect(strategy).to.beKindOf([CAMFormatStrategyExactResolution420f class]);

    expect(strategy.width).to.equal(kWidth);
    expect(strategy.height).to.equal(kHeight);
  });
});

context(@"highest resolution", ^{
  __block CAMFormatStrategyHighestResolution420f *formatStrategy;
  __block NSArray<AVCaptureDeviceFormat *> *formats;

  beforeEach(^{
    formatStrategy = [[CAMFormatStrategyHighestResolution420f alloc] init];
  });

  it(@"should select highest 4:2:0 full-range resolution", ^{
    formats = @[
      CAMAVCaptureDeviceFormatMock('420f', 300, 400),
      CAMAVCaptureDeviceFormatMock('420v', 300, 400),
      CAMAVCaptureDeviceFormatMock('420f', 600, 400),
      CAMAVCaptureDeviceFormatMock('420v', 600, 400),
      CAMAVCaptureDeviceFormatMock('420f', 300, 1000),
      CAMAVCaptureDeviceFormatMock('420v', 300, 1000),
      CAMAVCaptureDeviceFormatMock('yuvf', 300, 1000),
      CAMAVCaptureDeviceFormatMock('420f', 700, 400),
      CAMAVCaptureDeviceFormatMock('420v', 700, 400)
    ];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    CMVideoFormatDescriptionRef description = format.formatDescription;
    expect(CMFormatDescriptionGetMediaSubType(description)).to.equal('420f');
    expect(CMVideoFormatDescriptionGetDimensions(description).width).to.equal(300);
    expect(CMVideoFormatDescriptionGetDimensions(description).height).to.equal(1000);
  });

  it(@"should return nil when no formats are available", ^{
    formats = @[];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    expect(format).to.beNil();
  });

  it(@"should return nil when no 4:2:0 full-range formats are available", ^{
    formats = @[
      CAMAVCaptureDeviceFormatMock('420v', 300, 400),
      CAMAVCaptureDeviceFormatMock('420v', 600, 400),
      CAMAVCaptureDeviceFormatMock('420v', 300, 1000),
      CAMAVCaptureDeviceFormatMock('yuvf', 300, 1000),
      CAMAVCaptureDeviceFormatMock('420v', 700, 400)
    ];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    expect(format).to.beNil();
  });

  it(@"should return first match when multiple matches", ^{
    formats = @[
      CAMAVCaptureDeviceFormatMock('420v', 600, 400),
      CAMAVCaptureDeviceFormatMock('420f', 300, 1000),
      CAMAVCaptureDeviceFormatMock('420f', 300, 1000),
      CAMAVCaptureDeviceFormatMock('420f', 300, 1000),
      CAMAVCaptureDeviceFormatMock('420v', 300, 1000),
      CAMAVCaptureDeviceFormatMock('yuvf', 300, 1000),
      CAMAVCaptureDeviceFormatMock('420f', 700, 400),
      CAMAVCaptureDeviceFormatMock('420v', 700, 400)
    ];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    expect(format).to.beIdenticalTo(formats[1]);
    expect(format).toNot.beIdenticalTo(formats[2]);
    expect(format).toNot.beIdenticalTo(formats[3]);
  });
});

context(@"exact resolution", ^{
  static const NSUInteger kWidth = 600;
  static const NSUInteger kHeight = 400;

  __block CAMFormatStrategyExactResolution420f *formatStrategy;
  __block NSArray<AVCaptureDeviceFormat *> *formats;

  beforeEach(^{
    formatStrategy = [[CAMFormatStrategyExactResolution420f alloc] initWithWidth:kWidth
                                                                          height:kHeight];
  });

  it(@"should select exact 4:2:0 full-range resolution", ^{
    formats = @[
      CAMAVCaptureDeviceFormatMock('420f', 300, 400),
      CAMAVCaptureDeviceFormatMock('420v', 300, 400),
      CAMAVCaptureDeviceFormatMock('420f', 600, 400),
      CAMAVCaptureDeviceFormatMock('420v', 600, 400),
      CAMAVCaptureDeviceFormatMock('yuvf', 600, 400),
      CAMAVCaptureDeviceFormatMock('420f', 300, 1000),
      CAMAVCaptureDeviceFormatMock('420v', 300, 1000),
      CAMAVCaptureDeviceFormatMock('420f', 700, 400),
      CAMAVCaptureDeviceFormatMock('420v', 700, 400)
    ];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    CMVideoFormatDescriptionRef description = format.formatDescription;
    expect(CMFormatDescriptionGetMediaSubType(description)).to.equal('420f');
    expect(CMVideoFormatDescriptionGetDimensions(description).width).to.equal(kWidth);
    expect(CMVideoFormatDescriptionGetDimensions(description).height).to.equal(kHeight);
  });

  it(@"should return nil when no formats are available", ^{
    formats = @[];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    expect(format).to.beNil();
  });

  it(@"should return nil when no 4:2:0 full-range format available at exact resolution", ^{
    formats = @[
      CAMAVCaptureDeviceFormatMock('420v', 300, 400),
      CAMAVCaptureDeviceFormatMock('420v', 600, 400),
      CAMAVCaptureDeviceFormatMock('yuvf', 600, 400),
      CAMAVCaptureDeviceFormatMock('420v', 300, 1000),
      CAMAVCaptureDeviceFormatMock('420v', 700, 400)
    ];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    expect(format).to.beNil();
  });

  it(@"should return nil when no exact resolution format available at full-range", ^{
    formats = @[
      CAMAVCaptureDeviceFormatMock('420f', 300, 400),
      CAMAVCaptureDeviceFormatMock('420v', 300, 400),
      CAMAVCaptureDeviceFormatMock('420v', 600, 400),
      CAMAVCaptureDeviceFormatMock('yuvf', 600, 400),
      CAMAVCaptureDeviceFormatMock('420f', 300, 1000),
      CAMAVCaptureDeviceFormatMock('420v', 300, 1000),
      CAMAVCaptureDeviceFormatMock('420f', 700, 400),
      CAMAVCaptureDeviceFormatMock('420v', 700, 400)
    ];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    expect(format).to.beNil();
  });

  it(@"should return first match when multiple matches", ^{
    formats = @[
      CAMAVCaptureDeviceFormatMock('420f', 300, 400),
      CAMAVCaptureDeviceFormatMock('420f', 600, 400),
      CAMAVCaptureDeviceFormatMock('420f', 600, 400),
      CAMAVCaptureDeviceFormatMock('420f', 600, 400),
      CAMAVCaptureDeviceFormatMock('420v', 600, 400),
      CAMAVCaptureDeviceFormatMock('yuvf', 600, 400),
      CAMAVCaptureDeviceFormatMock('420f', 700, 400),
      CAMAVCaptureDeviceFormatMock('420v', 700, 400)
    ];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    expect(format).to.beIdenticalTo(formats[1]);
    expect(format).toNot.beIdenticalTo(formats[2]);
    expect(format).toNot.beIdenticalTo(formats[3]);
  });
});

SpecEnd
