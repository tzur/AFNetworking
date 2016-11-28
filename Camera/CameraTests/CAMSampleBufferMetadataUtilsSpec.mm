// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CAMSampleBufferMetadataUtils.h"

#import <ImageIO/CGImageProperties.h>
#import <LTEngine/LTCVPixelBufferExtensions.h>

#import "CAMTestUtils.h"
#import "CAMDevicePreset.h"

static NSDictionary *CAMSampleBufferMetadata(CMSampleBufferRef sampleBuffer,
                                             CMAttachmentMode attachmentMode) {
  CFDictionaryRef metadataRef = CMCopyDictionaryOfAttachments(NULL, sampleBuffer, attachmentMode);
  NSDictionary *metatdata = (__bridge_transfer NSDictionary *)metadataRef;
  return metatdata;
}

SpecBegin(CAMSampleBufferMetadata)

__block lt::Ref<CMSampleBufferRef> sampleBuffer;
__block NSDictionary *metadataDictionary;

beforeEach(^{
  sampleBuffer = CAMCreateImageSampleBuffer($(CAMPixelFormatBGRA), CGSizeMakeUniform(1));
  metadataDictionary = @{
    (__bridge NSString *)kCGImagePropertyExifWhiteBalance: @0,
    (__bridge NSString *)kCGImagePropertyDPIHeight: @72,
  };
});

context(@"CAMGePropagatabletMetadata", ^{
  it(@"should return nil for empty sample buffer", ^{
    NSDictionary *metadata = CAMGetPropagatableMetadata(sampleBuffer.get());
    expect(metadata).to.beNil();
  });

  it(@"should not reatain the returned propagatable metadata", ^{
    CMSetAttachments(sampleBuffer.get(), (__bridge CFDictionaryRef)metadataDictionary,
                     kCMAttachmentMode_ShouldPropagate);
    __weak NSDictionary *weakDict;
    @autoreleasepool {
      NSDictionary *metadata = CAMGetPropagatableMetadata(sampleBuffer.get());
      weakDict = metadata;
    }
    expect(weakDict).to.beNil();
  });
  
  it(@"should return a copy of the propagatable metadata", ^{
    CMSetAttachments(sampleBuffer.get(), (__bridge CFDictionaryRef)metadataDictionary,
                     kCMAttachmentMode_ShouldPropagate);

    NSDictionary *metadata1 = CAMGetPropagatableMetadata(sampleBuffer.get());
    NSDictionary *metadata2 = CAMGetPropagatableMetadata(sampleBuffer.get());

    expect(metadata1).to.equal(metadataDictionary);
    expect(metadata1).toNot.beIdenticalTo(metadataDictionary);
    expect(metadata2).to.equal(metadataDictionary);
    expect(metadata2).toNot.beIdenticalTo(metadataDictionary);
    expect(metadata1).toNot.beIdenticalTo(metadata2);
  });

  it(@"should not return the not-propagatable metadata", ^{
    CMSetAttachments(sampleBuffer.get(), (__bridge CFDictionaryRef)metadataDictionary,
                     kCMAttachmentMode_ShouldNotPropagate);

    NSDictionary *metadata = CAMGetPropagatableMetadata(sampleBuffer.get());

    expect(metadata).to.beNil();
  });
});

context(@"CAMSetPropagatableMetadata", ^{
  beforeEach(^{
    NSDictionary *sampleBufferMetadata = CAMSampleBufferMetadata(sampleBuffer.get(),
                                                                 kCMAttachmentMode_ShouldPropagate);
    expect(sampleBufferMetadata).to.beNil();
    CAMSetPropagatableMetadata(sampleBuffer.get(), metadataDictionary);
  });

  it(@"should set the given data as propagatable metadata", ^{
    NSDictionary *returnedMetadataDictionary =
        CAMSampleBufferMetadata(sampleBuffer.get(), kCMAttachmentMode_ShouldPropagate);
    expect(returnedMetadataDictionary).to.equal(metadataDictionary);
  });

  it(@"should not set the given data as not-propagatable metadata", ^{
    NSDictionary *returnedMetadataDictionary =
        CAMSampleBufferMetadata(sampleBuffer.get(), kCMAttachmentMode_ShouldNotPropagate);
    expect(returnedMetadataDictionary).to.beNil();
  });

  it(@"should update existing propagatable metadata", ^{
    NSDictionary *returnedMetadataDictionary =
        CAMSampleBufferMetadata(sampleBuffer.get(), kCMAttachmentMode_ShouldPropagate);
    expect(returnedMetadataDictionary).to.equal(metadataDictionary);

    NSDictionary *metadataDictionary2 = @{
      (__bridge NSString *)kCGImagePropertyExifWhiteBalance: @1,
    };
    CAMSetPropagatableMetadata(sampleBuffer.get(), metadataDictionary2);

    NSDictionary *expectedMetadataDictionary = @{
      (__bridge NSString *)kCGImagePropertyExifWhiteBalance: @1,
      (__bridge NSString *)kCGImagePropertyDPIHeight: @72,
    };
    returnedMetadataDictionary =
        CAMSampleBufferMetadata(sampleBuffer.get(), kCMAttachmentMode_ShouldPropagate);
    expect(returnedMetadataDictionary).to.equal(expectedMetadataDictionary);
  });
});

context(@"CAMCopyPropagatableMetadata", ^{
  __block lt::Ref<CMSampleBufferRef> sampleBuffer2;

  beforeEach(^{
    sampleBuffer2 = CAMCreateImageSampleBuffer($(CAMPixelFormatBGRA), CGSizeMakeUniform(1));

    NSDictionary *propagatableMetadata =
        CAMSampleBufferMetadata(sampleBuffer2.get(), kCMAttachmentMode_ShouldPropagate);
    expect(propagatableMetadata).to.beNil();

    NSDictionary *notPropagatableMetadata =
        CAMSampleBufferMetadata(sampleBuffer2.get(), kCMAttachmentMode_ShouldNotPropagate);
    expect(notPropagatableMetadata).to.beNil();
  });

  it(@"should copy propagatable metadata to target buffer with nil metatdata", ^{
    CMSetAttachments(sampleBuffer.get(), (__bridge CFDictionaryRef)metadataDictionary,
                     kCMAttachmentMode_ShouldPropagate);

    CAMCopyPropagatableMetadata(sampleBuffer.get(), sampleBuffer2.get());
    NSDictionary *returnedMetadataDictionary =
        CAMSampleBufferMetadata(sampleBuffer2.get(), kCMAttachmentMode_ShouldPropagate);
    expect(returnedMetadataDictionary).to.equal(metadataDictionary);
  });

  it(@"should not copy not-propagatable metadata", ^{
    CMSetAttachments(sampleBuffer.get(), (__bridge CFDictionaryRef)metadataDictionary,
                     kCMAttachmentMode_ShouldNotPropagate);
    NSDictionary *returnedMetadataDictionary =
        CAMSampleBufferMetadata(sampleBuffer.get(), kCMAttachmentMode_ShouldNotPropagate);
    expect(returnedMetadataDictionary).to.equal(metadataDictionary);

    CAMCopyPropagatableMetadata(sampleBuffer.get(), sampleBuffer2.get());

    returnedMetadataDictionary =
        CAMSampleBufferMetadata(sampleBuffer2.get(), kCMAttachmentMode_ShouldNotPropagate);
    expect(returnedMetadataDictionary).to.beNil();
  });

  it(@"should not change the target's metadata when the source's metadata is nil", ^{
    CMSetAttachments(sampleBuffer2.get(), (__bridge CFDictionaryRef)metadataDictionary,
                     kCMAttachmentMode_ShouldPropagate);

    CAMCopyPropagatableMetadata(sampleBuffer.get(), sampleBuffer2.get());
    NSDictionary *returnedMetadataDictionary =
        CAMSampleBufferMetadata(sampleBuffer2.get(), kCMAttachmentMode_ShouldPropagate);
    expect(returnedMetadataDictionary).to.equal(metadataDictionary);
  });

  it(@"should not change the target's metadata entries that aren't in the source's metadata", ^{
    CMSetAttachments(sampleBuffer2.get(), (__bridge CFDictionaryRef)metadataDictionary,
                     kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadataDictionary2 = @{
      (__bridge NSString *)kCGImagePropertyExifWhiteBalance: @1,
    };
    CMSetAttachments(sampleBuffer.get(), (__bridge CFDictionaryRef)metadataDictionary2,
                     kCMAttachmentMode_ShouldPropagate);

    CAMCopyPropagatableMetadata(sampleBuffer.get(), sampleBuffer2.get());
    NSDictionary *returnedMetadataDictionary = 
        CAMSampleBufferMetadata(sampleBuffer2.get(), kCMAttachmentMode_ShouldPropagate);
    NSDictionary *expectedMetadataDictionary = @{
      (__bridge NSString *)kCGImagePropertyExifWhiteBalance: @1,
      (__bridge NSString *)kCGImagePropertyDPIHeight: @72,
    };
    expect(returnedMetadataDictionary).to.equal(expectedMetadataDictionary);
  });
});

SpecEnd
