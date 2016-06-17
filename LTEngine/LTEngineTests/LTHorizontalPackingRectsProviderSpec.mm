// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTHorizontalPackingRectsProvider.h"

SpecBegin(LTHorizontalPackingRectsProvider)

__block LTHorizontalPackingRectsProvider *provider;

beforeEach(^{
  provider = [[LTHorizontalPackingRectsProvider alloc] init];
});

afterEach(^{
  provider = nil;
});

context(@"packing with invalid sizes", ^{
  it(@"should raise when sizes map contains a size with non positive width or height", ^{
    lt::unordered_map<NSString *, CGSize> sizes1 {
      {@"1", CGSizeMakeUniform(1)},
      {@"2", CGSizeMake(0, 1)},
    };

    expect(^{
      [provider packingOfSizes:sizes1];
    }).to.raise(NSInvalidArgumentException);

    lt::unordered_map<NSString *, CGSize> sizes2 {
      {@"1", CGSizeMakeUniform(1)},
      {@"2", CGSizeMake(1, 0)},
    };

    expect(^{
      [provider packingOfSizes:sizes2];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"packing valid sizes", ^{
  __block lt::unordered_map<NSString *, CGSize> sizes;
  __block lt::unordered_map<NSString *, CGRect> packingRects;

  beforeEach(^{
    sizes = lt::unordered_map<NSString *, CGSize> {
      {@"1", CGSizeMakeUniform(1)},
      {@"2", CGSizeMake(2, 4)},
      {@"3", CGSizeMakeUniform(3)}
    };

    packingRects = [provider packingOfSizes:sizes];
  });

  it(@"should produce area rects with correct sizes", ^{
    expect(packingRects[@"1"].size).to.equal(CGSizeMakeUniform(1));
    expect(packingRects[@"2"].size).to.equal(CGSizeMake(2, 4));
    expect(packingRects[@"3"].size).to.equal(CGSizeMakeUniform(3));
  });

  it(@"should produce areas with correct origins", ^{
    std::vector<CGRect> areasSortedByXOrigin;

    for (const auto &keyValue : packingRects) {
      areasSortedByXOrigin.push_back(keyValue.second);
    }

    std::sort(areasSortedByXOrigin.begin(), areasSortedByXOrigin.end(), [] (auto &lhs, auto &rhs) {
      return lhs.origin.x < rhs.origin.x;
    });

    CGFloat widthsSum = 0;
    for (NSUInteger i = 0; i < areasSortedByXOrigin.size(); ++i) {
      expect(areasSortedByXOrigin[i].origin.x).to.equal(widthsSum);
      widthsSum += areasSortedByXOrigin[i].size.width;
    }
  });
});

SpecEnd
