// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMFormatStrategy.h"

#import "AVCaptureDeviceFormat+MediaProperties.h"
#import "CAMFakeAVCaptureDeviceFormat.h"

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

  beforeEach(^{
    formatStrategy = [[CAMFormatStrategyHighestResolution420f alloc] init];
  });

  it(@"should select highest 4:2:0 full-range resolution", ^{
    NSArray<AVCaptureDeviceFormat *> *formats = @[
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:300 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:300 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:600 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:600 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:300 height:1000],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:300 height:1000],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'yuvf' width:300 height:1000],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:700 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:700 height:400]
    ];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    expect(format.cam_mediaSubType).to.equal('420f');
    expect(format.cam_width).to.equal(300);
    expect(format.cam_height).to.equal(1000);
  });

  it(@"should return nil when no formats are available", ^{
    NSArray<AVCaptureDeviceFormat *> *formats = @[];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    expect(format).to.beNil();
  });

  it(@"should return nil when no 4:2:0 full-range formats are available", ^{
    NSArray<AVCaptureDeviceFormat *> *formats = @[
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:300 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:600 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:300 height:1000],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'yuvf' width:300 height:1000],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:700 height:400]
    ];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    expect(format).to.beNil();
  });

  it(@"should return first match when multiple matches", ^{
    NSArray<AVCaptureDeviceFormat *> *formats = @[
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:600 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:300 height:1000],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:300 height:1000],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:300 height:1000],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:300 height:1000],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'yuvf' width:300 height:1000],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:700 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:700 height:400]
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

  beforeEach(^{
    formatStrategy = [[CAMFormatStrategyExactResolution420f alloc] initWithWidth:kWidth
                                                                          height:kHeight];
  });

  it(@"should select exact 4:2:0 full-range resolution", ^{
    NSArray<AVCaptureDeviceFormat *> *formats = @[
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:300 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:300 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:600 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:600 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'yuvf' width:600 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:300 height:1000],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:300 height:1000],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:700 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:700 height:400]
    ];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    expect(format.cam_mediaSubType).to.equal('420f');
    expect(format.cam_width).to.equal(kWidth);
    expect(format.cam_height).to.equal(kHeight);
  });

  it(@"should return nil when no formats are available", ^{
    NSArray<AVCaptureDeviceFormat *> *formats = @[];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    expect(format).to.beNil();
  });

  it(@"should return nil when no 4:2:0 full-range format available at exact resolution", ^{
    NSArray<AVCaptureDeviceFormat *> *formats = @[
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:300 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:600 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'yuvf' width:600 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:300 height:1000],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:700 height:400]
    ];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    expect(format).to.beNil();
  });

  it(@"should return nil when no exact resolution format available at full-range", ^{
    NSArray<AVCaptureDeviceFormat *> *formats = @[
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:300 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:300 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:600 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'yuvf' width:600 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:300 height:1000],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:300 height:1000],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:700 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:700 height:400]
    ];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    expect(format).to.beNil();
  });

  it(@"should return first match when multiple matches", ^{
    NSArray<AVCaptureDeviceFormat *> *formats = @[
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:300 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:600 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:600 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:600 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:600 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'yuvf' width:600 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420f' width:700 height:400],
      [CAMFakeAVCaptureDeviceFormat formatWithSubtype:'420v' width:700 height:400]
    ];

    AVCaptureDeviceFormat *format = [formatStrategy formatFrom:formats];
    expect(format).to.beIdenticalTo(formats[1]);
    expect(format).toNot.beIdenticalTo(formats[2]);
    expect(format).toNot.beIdenticalTo(formats[3]);
  });
});

SpecEnd
