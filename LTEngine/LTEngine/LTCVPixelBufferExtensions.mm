// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "LTCVPixelBufferExtensions.h"

#import "LTGLPixelFormat.h"

NS_ASSUME_NONNULL_BEGIN

lt::Ref<CVPixelBufferRef> LTCVPixelBufferCreate(size_t width, size_t height,
                                                OSType pixelFormatType) {
  NSDictionary *attributes = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}};

  CVPixelBufferRef pixelBufferRef;
  CVReturn result = CVPixelBufferCreate(NULL, width, height, pixelFormatType,
                                        (__bridge CFDictionaryRef)attributes,
                                        &pixelBufferRef);
  if (result != kCVReturnSuccess) {
    [LTGLException raise:kLTCVPixelBufferCreationFailedException
                  format:@"Failed creating pixel buffer (%zu x %zu, format=0x%08X) with error %d",
     width, height, (unsigned int)pixelFormatType, (int)result];
  }

  return lt::Ref<CVPixelBufferRef>(pixelBufferRef);
}

void LTCVPixelBufferLockAndExecute(CVPixelBufferRef pixelBuffer, CVPixelBufferLockFlags lockFlags,
                                   LTVoidBlock block) {
  LTParameterAssert(block);

  CVReturn lockResult = CVPixelBufferLockBaseAddress(pixelBuffer, lockFlags);
  if (kCVReturnSuccess != lockResult) {
    [LTGLException raise:kLTCVPixelBufferLockingFailedException
                  format:@"Failed locking base address of pixel buffer with error %d",
     (int)lockResult];
  }

  @try {
    block();
  } @finally {
    CVReturn unlockResult = CVPixelBufferUnlockBaseAddress(pixelBuffer, lockFlags);
    if (kCVReturnSuccess != unlockResult) {
      [LTGLException raise:kLTCVPixelBufferLockingFailedException
                    format:@"Failed unlocking base address of pixel buffer with error %d",
       (int)unlockResult];
    }
  }
}

void LTCVPixelBufferImage(CVPixelBufferRef pixelBuffer, CVPixelBufferLockFlags lockFlags,
                          LTCVPixelBufferWriteBlock block) {
  LTParameterAssert(block);
  LTParameterAssert(!CVPixelBufferIsPlanar(pixelBuffer),
                    @"The given pixel buffer must not be planar");

  LTGLPixelFormat *pixelFormat = [[LTGLPixelFormat alloc] initWithCVPixelFormatType:
                                  CVPixelBufferGetPixelFormatType(pixelBuffer)];

  LTCVPixelBufferLockAndExecute(pixelBuffer, lockFlags, ^{
    void *base = CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);

    cv::Mat image((int)height, (int)width, pixelFormat.matType, base, bytesPerRow);
    block(&image);
  });
}

void LTCVPixelBufferImageForReading(CVPixelBufferRef pixelBuffer, LTCVPixelBufferReadBlock block) {
  LTCVPixelBufferImage(pixelBuffer, kCVPixelBufferLock_ReadOnly, ^(cv::Mat *image) {
    block(*image);
  });
}

void LTCVPixelBufferImageForWriting(CVPixelBufferRef pixelBuffer, LTCVPixelBufferWriteBlock block) {
  LTCVPixelBufferImage(pixelBuffer, 0, block);
}

void LTCVPixelBufferPlaneImage(CVPixelBufferRef pixelBuffer, size_t planeIndex,
                               CVPixelBufferLockFlags lockFlags, LTCVPixelBufferWriteBlock block) {
  LTParameterAssert(block);
  LTParameterAssert(CVPixelBufferIsPlanar(pixelBuffer), @"The given pixel buffer must be planar");

  const size_t planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
  LTParameterAssert(planeIndex < planeCount, @"The given plane index %zu is invalid. "
                    "This pixel buffer has only %zu planes", planeIndex, planeCount);

  LTGLPixelFormat *pixelFormat =
      [[LTGLPixelFormat alloc] initWithPlanarCVPixelFormatType:
       CVPixelBufferGetPixelFormatType(pixelBuffer) planeIndex:planeIndex];

  LTCVPixelBufferLockAndExecute(pixelBuffer, lockFlags, ^{
    void *base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, planeIndex);
    size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex);
    size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, planeIndex);

    cv::Mat image((int)height, (int)width, pixelFormat.matType, base, bytesPerRow);
    block(&image);
  });
}

void LTCVPixelBufferPlaneImageForReading(CVPixelBufferRef pixelBuffer, size_t planeIndex,
                                         LTCVPixelBufferReadBlock block) {
  LTCVPixelBufferPlaneImage(pixelBuffer, planeIndex, kCVPixelBufferLock_ReadOnly,
                            ^(cv::Mat *image) {
    block(*image);
  });
}

void LTCVPixelBufferPlaneImageForWriting(CVPixelBufferRef pixelBuffer, size_t planeIndex,
                                         LTCVPixelBufferWriteBlock block) {
  LTCVPixelBufferPlaneImage(pixelBuffer, planeIndex, 0, block);
}

void LTCVPixelBufferImages(CVPixelBufferRef pixelBuffer, CVPixelBufferLockFlags lockFlags,
                           LTCVPixelBufferImagesBlock block) {
  LTParameterAssert(block);

  if (!CVPixelBufferIsPlanar(pixelBuffer)) {
    LTCVPixelBufferImage(pixelBuffer, lockFlags, ^(cv::Mat *image) {
      block({*image});
    });
  } else {
    const size_t planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);

    LTCVPixelBufferLockAndExecute(pixelBuffer, lockFlags, ^{
      std::vector<cv::Mat> images;

      for (size_t planeIndex = 0; planeIndex < planeCount; ++planeIndex) {
        LTGLPixelFormat *planeFormat =
            [[LTGLPixelFormat alloc] initWithPlanarCVPixelFormatType:pixelFormat
                                                          planeIndex:planeIndex];

        void *base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, planeIndex);
        size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex);
        size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, planeIndex);

        images.emplace_back((int)height, (int)width, planeFormat.matType, base, bytesPerRow);
      }

      block(images);
    });
  }
}

void LTCVPixelBufferImagesForReading(CVPixelBufferRef pixelBuffer,
                                     LTCVPixelBufferImagesBlock block) {
  LTCVPixelBufferImages(pixelBuffer, kCVPixelBufferLock_ReadOnly,
                        ^(const std::vector<cv::Mat> &images) {
    block(images);
  });
}

void LTCVPixelBufferImagesForWriting(CVPixelBufferRef pixelBuffer,
                                     LTCVPixelBufferImagesBlock block) {
  LTCVPixelBufferImages(pixelBuffer, 0, ^(const std::vector<cv::Mat> &images) {
    block(images);
  });
}

NS_ASSUME_NONNULL_END
