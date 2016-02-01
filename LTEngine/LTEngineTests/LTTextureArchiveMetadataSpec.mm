// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureArchiveMetadata.h"

#import "LTTexture+Factory.h"
#import "LTTextureArchiveType.h"
#import "LTTextureMetadata.h"

SpecBegin(LTTextureArchiveMetadata)

context(@"initialization", ^{
  it(@"should initialize with texture metadata and archive type", ^{
    LTTextureMetadata *textureMetadata = [[LTTextureMetadata alloc] init];
    LTTextureArchiveMetadata *metadata = [[LTTextureArchiveMetadata alloc]
                                          initWithArchiveType:$(LTTextureArchiveTypeJPEG)
                                          textureMetadata:textureMetadata];
    expect(metadata.archiveType).to.equal($(LTTextureArchiveTypeJPEG));
    expect(metadata.textureMetadata).to.equal(textureMetadata);
  });
});

context(@"deserialize", ^{
  __block NSError *error;
  __block LTTextureMetadata *textureMetadata;
  __block LTTextureArchiveMetadata *metadata;

  beforeEach(^{
    textureMetadata = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 8)].metadata;

    NSDictionary *json = @{
      @"archiveType": @"LTTextureArchiveTypeJPEG",
      @"textureMetadata": [MTLJSONAdapter JSONDictionaryFromModel:textureMetadata]
    };

    metadata = [MTLJSONAdapter modelOfClass:[LTTextureArchiveMetadata class]
                         fromJSONDictionary:json error:&error];
  });

  afterEach(^{
    error = nil;
    metadata = nil;
    textureMetadata = nil;
  });

  it(@"should deserialize without errors", ^{
    expect(error).to.beNil();
  });

  it(@"should deserialize correctly", ^{
    expect(metadata.archiveType).to.equal($(LTTextureArchiveTypeJPEG));
    expect(metadata.textureMetadata).to.equal(textureMetadata);
  });
});

SpecEnd
