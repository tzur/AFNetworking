// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNOceanAssetDescriptor.h"

#import "NSURL+Ocean.h"
#import "PTNOceanAssetSearchResponse.h"
#import "PTNOceanEnums.h"

SpecBegin(PTNOceanAssetDescriptor)

__block NSDictionary<NSString *, id> *descriptorDictionary;
__block PTNOceanAssetDescriptor *descriptor;
__block NSError *parseError;

beforeEach(^{
  descriptorDictionary = @{
    @"id": @"foo",
    @"asset_type": @"photo",
    @"source_id": @"pixabay",
    @"all_sizes": @[
      @{
        @"height": @8,
        @"width": @9,
        @"url" : @"https://bar.com/full.jpg"
      },
      @{
        @"height": @10,
        @"width": @11,
        @"url" : @"https://bar.com/thumbnail.jpg"
      }
    ]
  };
  descriptor = [MTLJSONAdapter modelOfClass:[PTNOceanAssetDescriptor class]
                         fromJSONDictionary:descriptorDictionary error:&parseError];
});

context(@"invalid dictionaries", ^{
  it(@"should return nil for an invalid dictionary", ^{
    auto invalidDictionary = [descriptorDictionary mtl_dictionaryByRemovingEntriesWithKeys:
                              [NSSet setWithObject:@"id"]];
    expect([MTLJSONAdapter modelOfClass:[PTNOceanAssetDescriptor class]
                     fromJSONDictionary:invalidDictionary error:nil]).to.beNil();
  });

  it(@"should return nil for an invalid sub-dictionary", ^{
    auto invalidDictionary = @{
      @"asset_type": @"photo",
      @"id": @"foo",
      @"source_id": @"pixabay",
      @"all_sizes": @[
        @{
          @"height": @8,
          @"width": @9
        }
      ]
    };
    expect([MTLJSONAdapter modelOfClass:[PTNOceanAssetDescriptor class]
                     fromJSONDictionary:invalidDictionary error:nil]).to.beNil();
  });

  it(@"should return nil for an invalid asset dictionary", ^{
    auto invalidDictionary = @{
      @"width": @9,
      @"height": @8
    };
    expect([MTLJSONAdapter modelOfClass:[PTNOceanImageAssetInfo class]
                     fromJSONDictionary:invalidDictionary error:nil]).to.beNil();
  });
});

it(@"should deserialize", ^{
  expect(descriptor.identifier).to.equal(@"foo");
  expect(descriptor.type).to.equal($(PTNOceanAssetTypePhoto));
  expect(descriptor.source).to.equal($(PTNOceanAssetSourcePixabay));
  expect(descriptor.images).to.haveCountOf(2);
  expect(descriptor.images[0].height).to.equal(@8);
  expect(descriptor.images[0].width).to.equal(@9);
  expect(descriptor.images[0].url.absoluteString).to.equal(@"https://bar.com/full.jpg");
  expect(descriptor.images[1].height).to.equal(@10);
  expect(descriptor.images[1].width).to.equal(@11);
  expect(descriptor.images[1].url.absoluteString)
      .to.equal(@"https://bar.com/thumbnail.jpg");
  expect(descriptor.creationDate).to.beNil();
  expect(descriptor.modificationDate).to.beNil();
  expect(descriptor.filename).to.beNil();
  expect(descriptor.duration).to.equal(0);
  expect(descriptor.assetDescriptorCapabilities).to.equal(PTNAssetDescriptorCapabilityNone);
  expect(descriptor.ptn_identifier)
      .to.equal([NSURL ptn_oceanAssetURLWithSource:descriptor.source
                                        identifier:descriptor.identifier]);
  expect(descriptor.localizedTitle).to.beNil();
  expect(descriptor.descriptorCapabilities).to.equal(PTNDescriptorCapabilityNone);
  expect(descriptor.descriptorTraits)
      .to.equal([NSSet setWithObject:kPTNDescriptorTraitCloudBasedKey]);
});

it(@"should serialize", ^{
  expect([MTLJSONAdapter JSONDictionaryFromModel:descriptor]).to.equal(descriptorDictionary);
});

SpecEnd
