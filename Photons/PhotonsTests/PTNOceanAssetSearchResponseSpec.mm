// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNOceanAssetSearchResponse.h"

#import "NSURL+Ocean.h"
#import "PTNOceanAssetDescriptor.h"
#import "PTNOceanEnums.h"

SpecBegin(PTNOceanAssetSearchResponse)

__block NSDictionary<NSString *, id> *responseDictionary;
__block PTNOceanAssetSearchResponse *response;
__block NSError *parseError;

beforeEach(^{
  responseDictionary = @{
    @"result_count": @1,
    @"page": @2,
    @"total_pages": @3,
    @"total_results": @4,
    @"results": @[
      @{
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
      }
    ]
  };
  response = [MTLJSONAdapter modelOfClass:[PTNOceanAssetSearchResponse class]
                       fromJSONDictionary:responseDictionary error:&parseError];
});

it(@"should return nil for an invalid dictionary", ^{
  auto invalidDictionary = [responseDictionary mtl_dictionaryByRemovingEntriesWithKeys:
                            [NSSet setWithObject:@"page"]];
  expect([MTLJSONAdapter modelOfClass:[PTNOceanAssetSearchResponse class]
                   fromJSONDictionary:invalidDictionary error:nil]).to.beNil();
});

it(@"should deserialize", ^{
  expect(parseError).to.beNil();
  expect(response.count).to.equal(@1);
  expect(response.page).to.equal(@2);
  expect(response.pagesCount).to.equal(@3);
  expect(response.totalCount).to.equal(@4);
  expect(response.results).to.haveCountOf(1);

  PTNOceanAssetDescriptor *descriptor = response.results.firstObject;

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
  expect(descriptor.videos).to.beEmpty();
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

SpecEnd
