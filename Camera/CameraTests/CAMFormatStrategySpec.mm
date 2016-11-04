// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMFormatStrategy.h"

#import <AVFoundation/AVFoundation.h>

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
  __block NSArray<AVCaptureDeviceFormat *> *formats;

  beforeEach(^{
    formatStrategy = [[CAMFormatStrategyHighestResolution420f alloc] init];
  });

  it(@"should select highest 4:2:0 full-range resolution", ^{
    formats = @[
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
    formats = @[
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
  __block NSArray<AVCaptureDeviceFormat *> *formats;

  beforeEach(^{
    formatStrategy = [[CAMFormatStrategyExactResolution420f alloc] initWithWidth:kWidth
                                                                          height:kHeight];
  });

  it(@"should select exact 4:2:0 full-range resolution", ^{
    formats = @[
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
    formats = @[
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
    formats = @[
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
