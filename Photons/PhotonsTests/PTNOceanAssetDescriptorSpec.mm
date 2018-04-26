// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNOceanAssetDescriptor.h"

#import <LTKit/NSArray+NSSet.h>

#import "NSURL+Ocean.h"
#import "PTNOceanAssetSearchResponse.h"
#import "PTNOceanEnums.h"

SpecBegin(PTNOceanVideoAssetInfo)

it(@"should deserialize", ^{
  auto AVAssetInfo = @{
    @"height": @8,
    @"width": @9,
    @"size": @1337,
    @"download_url" : @"https://bar.com/full.mp4",
    @"streaming_url": @"bar://steam.foo"
  };
  PTNOceanVideoAssetInfo *assetInfo = [MTLJSONAdapter modelOfClass:[PTNOceanVideoAssetInfo class]
                                                fromJSONDictionary:AVAssetInfo error:nil];

  expect(assetInfo.height).to.equal(@8);
  expect(assetInfo.width).to.equal(@9);
  expect(assetInfo.size).to.equal(@1337);
  expect(assetInfo.url.absoluteString).to.equal(@"https://bar.com/full.mp4");
  expect(assetInfo.streamURL.absoluteString).to.equal(@"bar://steam.foo");
});

SpecEnd

SpecBegin(PTNOceanAssetDescriptor)

__block NSDictionary<NSString *, id> *descriptorDictionary;
__block PTNOceanAssetDescriptor *descriptor;
__block NSError *parseError;

it(@"should return nil for an invalid asset dictionary", ^{
  auto invalidDictionary = @{
    @"width": @9,
    @"height": @8
  };
  expect([MTLJSONAdapter modelOfClass:[PTNOceanImageAssetInfo class]
                   fromJSONDictionary:invalidDictionary error:nil]).to.beNil();
});

context(@"photos", ^{
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
    expect(descriptor.videos).to.beEmpty();
    expect(descriptor.creationDate).to.beNil();
    expect(descriptor.modificationDate).to.beNil();
    expect(descriptor.filename).to.beNil();
    expect(descriptor.duration).to.equal(0);
    expect(descriptor.assetDescriptorCapabilities).to.equal(PTNAssetDescriptorCapabilityNone);
    expect(descriptor.ptn_identifier)
        .to.equal([NSURL ptn_oceanAssetURLWithSource:descriptor.source
                                           assetType:descriptor.type
                                          identifier:descriptor.identifier]);
    expect(descriptor.localizedTitle).to.beNil();
    expect(descriptor.descriptorCapabilities).to.equal(PTNDescriptorCapabilityNone);
    expect(descriptor.descriptorTraits)
        .to.equal([NSSet setWithObject:kPTNDescriptorTraitCloudBasedKey]);
  });
});

context(@"video", ^{
  beforeEach(^{
    descriptorDictionary = @{
      @"id": @"foo",
      @"asset_type": @"video",
      @"source_id": @"pixabay",
      @"duration": @1337,
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
      ],
      @"videos": @[
        @{
          @"height": @8,
          @"width": @9,
          @"size": @1337,
          @"download_url" : @"https://bar.com/full.mp4",
          @"streaming_url": @"bar://steam.foo/blah"
        },
        @{
          @"height": @10,
          @"width": @11,
          @"size": @999,
          @"download_url" : @"https://foo.com/movie.mov",
          @"streaming_url": @"bar://twitch.tv/blah/cs"
        }
      ]
    };
    descriptor = [MTLJSONAdapter modelOfClass:[PTNOceanAssetDescriptor class]
                           fromJSONDictionary:descriptorDictionary error:&parseError];
  });

  context(@"invalid dictionaries", ^{
    it(@"should return nil for dictionary without id", ^{
      auto invalidDictionary = [descriptorDictionary mtl_dictionaryByRemovingEntriesWithKeys:
                                [NSSet setWithObject:@"id"]];
      expect([MTLJSONAdapter modelOfClass:[PTNOceanAssetDescriptor class]
                       fromJSONDictionary:invalidDictionary error:nil]).to.beNil();
    });

    it(@"should return nil for dictionary without duration", ^{
      auto invalidDictionary = [descriptorDictionary mtl_dictionaryByRemovingEntriesWithKeys:
                                [NSSet setWithObject:@"duration"]];
      expect([MTLJSONAdapter modelOfClass:[PTNOceanAssetDescriptor class]
                       fromJSONDictionary:invalidDictionary error:nil]).to.beNil();
    });

    it(@"should return nil for dictionary with empty video list", ^{
      auto invalidDictionary = [descriptorDictionary mtl_dictionaryByRemovingEntriesWithKeys:
                                [NSSet setWithObject:@"videos"]];
      expect([MTLJSONAdapter modelOfClass:[PTNOceanAssetDescriptor class]
                       fromJSONDictionary:invalidDictionary error:nil]).to.beNil();
    });

    it(@"should return nil for an invalid sub-dictionary", ^{
      auto invalidDictionary = @{
        @"asset_type": @"video",
        @"id": @"foo",
        @"source_id": @"pixabay",
        @"duration": @1337,
        @"all_sizes": @[
          @{
            @"height": @8,
            @"width": @9,
            @"url" : @"https://bar.com/thumbnail.jpg"
          }
        ],
        @"videos": @[
          @{
            @"height": @8,
            @"width": @9,
            @"size": @1337,
          }
        ]
      };
      expect([MTLJSONAdapter modelOfClass:[PTNOceanAssetDescriptor class]
                       fromJSONDictionary:invalidDictionary error:nil]).to.beNil();
    });
  });

  it(@"should deserialize", ^{
    expect(descriptor.identifier).to.equal(@"foo");
    expect(descriptor.type).to.equal($(PTNOceanAssetTypeVideo));
    expect(descriptor.source).to.equal($(PTNOceanAssetSourcePixabay));
    expect(descriptor.images).to.haveCountOf(2);
    expect(descriptor.images[0].height).to.equal(@8);
    expect(descriptor.images[0].width).to.equal(@9);
    expect(descriptor.images[0].url.absoluteString).to.equal(@"https://bar.com/full.jpg");
    expect(descriptor.images[1].height).to.equal(@10);
    expect(descriptor.images[1].width).to.equal(@11);
    expect(descriptor.images[1].url.absoluteString)
        .to.equal(@"https://bar.com/thumbnail.jpg");
    expect(descriptor.videos).to.haveCountOf(2);
    expect(descriptor.videos[0].height).to.equal(@8);
    expect(descriptor.videos[0].width).to.equal(@9);
    expect(descriptor.videos[0].size).to.equal(@1337);
    expect(descriptor.videos[0].url.absoluteString).to.equal(@"https://bar.com/full.mp4");
    expect(descriptor.videos[0].streamURL.absoluteString).to.equal(@"bar://steam.foo/blah");
    expect(descriptor.videos[1].height).to.equal(@10);
    expect(descriptor.videos[1].width).to.equal(@11);
    expect(descriptor.videos[1].size).to.equal(@999);
    expect(descriptor.videos[1].url.absoluteString).to.equal(@"https://foo.com/movie.mov");
    expect(descriptor.videos[1].streamURL.absoluteString).to.equal(@"bar://twitch.tv/blah/cs");
    expect(descriptor.creationDate).to.beNil();
    expect(descriptor.modificationDate).to.beNil();
    expect(descriptor.filename).to.beNil();
    expect(descriptor.duration).to.equal(@1337);
    expect(descriptor.assetDescriptorCapabilities).to.equal(PTNAssetDescriptorCapabilityNone);
    expect(descriptor.ptn_identifier)
        .to.equal([NSURL ptn_oceanAssetURLWithSource:descriptor.source
                                           assetType:descriptor.type
                                          identifier:descriptor.identifier]);
    expect(descriptor.localizedTitle).to.beNil();
    expect(descriptor.descriptorCapabilities).to.equal(PTNDescriptorCapabilityNone);
    expect(descriptor.descriptorTraits)
        .to.equal([@[kPTNDescriptorTraitCloudBasedKey, kPTNDescriptorTraitAudiovisualKey] lt_set]);
  });
});

SpecEnd
