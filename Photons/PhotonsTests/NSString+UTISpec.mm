// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSString+UTI.h"

#import <MobileCoreServices/MobileCoreServices.h>

SpecBegin(NSString_UTI)

context(@"isGIF", ^{
  it(@"should return YES when string is GIF UTI", ^{
    expect([(NSString *)kUTTypeGIF ptn_isGIFUTI]).to.beTruthy();
  });

  it(@"should return NO when string is not GIF UTI", ^{
    expect([(NSString *)kUTTypeBMP ptn_isGIFUTI]).to.beFalsy();
  });
});

context(@"isRaw", ^{
  it(@"should return YES when string conforms to raw image UTI", ^{
    expect([@"com.nikon.raw-image" ptn_isRawImageUTI]).to.beTruthy();
  });

  it(@"should return NO when string is not raw image UTI", ^{
    expect([(NSString *)kUTTypeBMP ptn_isRawImageUTI]).to.beFalsy();
  });
});

SpecEnd
