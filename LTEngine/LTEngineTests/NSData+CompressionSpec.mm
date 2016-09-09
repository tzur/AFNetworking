// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSData+Compression.h"

#import "NSErrorCodes+LTEngine.h"

SpecBegin(NSData_Compression)

static NSString * const kLTCompressionExamples = @"CompressionExamples";
static NSString * const kLTCompressionTypeKey = @"CompressionType";

sharedExamplesFor(kLTCompressionExamples, ^(NSDictionary *data) {
  __block LTCompressionType compressionType;

  beforeEach(^{
    compressionType = (LTCompressionType)[data[kLTCompressionTypeKey] unsignedIntegerValue];
  });

  it(@"should compress and decompress small data", ^{
    std::vector<int> data(17);
    std::iota(data.begin(), data.end(), 1);

    NSData *input = [NSData dataWithBytes:data.data() length:data.size() * sizeof(int)];

    NSError *compressionError;
    NSMutableData * _Nullable compressed =
        [input lt_compressWithCompressionType:compressionType error:&compressionError];

    NSError *decompressionError;
    NSMutableData * _Nullable decompressed =
        [compressed lt_decompressWithCompressionType:compressionType
                                               error:&decompressionError];

    expect(decompressed).to.equal(input);
    expect(compressionError).to.beNil();
    expect(decompressionError).to.beNil();
  });

  it(@"should compress and decompress large data", ^{
    std::vector<int> data(103451);
    std::iota(data.begin(), data.end(), 1);

    NSData *input = [NSData dataWithBytes:data.data() length:data.size() * sizeof(int)];

    NSError *compressionError;
    NSMutableData * _Nullable compressed =
        [input lt_compressWithCompressionType:compressionType error:&compressionError];

    NSError *decompressionError;
    NSMutableData * _Nullable decompressed =
        [compressed lt_decompressWithCompressionType:compressionType
                                               error:&decompressionError];

    expect(decompressed).to.equal(input);
    expect(compressionError).to.beNil();
    expect(decompressionError).to.beNil();
  });

  it(@"should error when decompressing invalid data", ^{
    NSMutableData *input = [NSMutableData dataWithLength:33];

    NSError *error;
    NSMutableData * _Nullable decompressed =
        [input lt_decompressWithCompressionType:compressionType error:&error];

    expect(decompressed).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(LTErrorCodeCompressionFailed);
  });
});

itShouldBehaveLike(kLTCompressionExamples, @{kLTCompressionTypeKey: @(LTCompressionTypeLZFSE)});
itShouldBehaveLike(kLTCompressionExamples, @{kLTCompressionTypeKey: @(LTCompressionTypeLZ4)});
itShouldBehaveLike(kLTCompressionExamples, @{kLTCompressionTypeKey: @(LTCompressionTypeLZMA)});
itShouldBehaveLike(kLTCompressionExamples, @{kLTCompressionTypeKey: @(LTCompressionTypeZLIB)});

SpecEnd
