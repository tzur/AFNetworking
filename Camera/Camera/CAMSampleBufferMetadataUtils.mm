// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CAMSampleBufferMetadataUtils.h"

NS_ASSUME_NONNULL_BEGIN

NSDictionary * _Nullable CAMGetPropagatableMetadata(CMSampleBufferRef sampleBuffer) {
  CFDictionaryRef metadataRef = CMCopyDictionaryOfAttachments(NULL, sampleBuffer,
                                                              kCMAttachmentMode_ShouldPropagate);
  NSDictionary *metatdata = (__bridge_transfer NSDictionary *)metadataRef;
  return metatdata;
}

void CAMSetPropagatableMetadata(CMSampleBufferRef sampleBuffer, NSDictionary *metadata) {
  CMSetAttachments(sampleBuffer, (__bridge CFDictionaryRef)metadata,
                   kCMAttachmentMode_ShouldPropagate);
}

void CAMCopyPropagatableMetadata(CMSampleBufferRef source, CMSampleBufferRef target) {
  CMPropagateAttachments(source, target);
}

NS_ASSUME_NONNULL_END
