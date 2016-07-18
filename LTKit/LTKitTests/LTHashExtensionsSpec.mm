// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTHashExtensions.h"

SpecBegin(LTHashExtensions)

context(@"std containers", ^{
  context(@"hashing with unordered_map", ^{
    it(@"should hash std::pair", ^{
      typedef std::pair<int, bool> LTTestPair;
      const std::unordered_map<LTTestPair, int, std::hash<LTTestPair>> map{
        {{7, true}, 1},
        {{7, false}, 2},
        {{5, true}, 3},
        {{5, false}, 4}
      };

      expect(map.at({7, true})).to.equal(1);
      expect(map.at({7, false})).to.equal(2);
      expect(map.at({5, true})).to.equal(3);
      expect(map.at({5, false})).to.equal(4);
    });

    it(@"should hash std::tuple", ^{
      typedef std::tuple<int, bool, std::string> LTTestTuple;
      const std::unordered_map<LTTestTuple, int, std::hash<LTTestTuple>> map{
        {{7, true, "foo"}, 1},
        {{7, false, "bar"}, 2},
        {{5, true, "foo"}, 3},
        {{5, false, "baz"}, 4}
      };

      expect(map.at({7, true, "foo"})).to.equal(1);
      expect(map.at({7, false, "bar"})).to.equal(2);
      expect(map.at({5, true, "foo"})).to.equal(3);
      expect(map.at({5, false, "baz"})).to.equal(4);
    });
  });

  context(@"hashing std::vector", ^{
    it(@"should hash std::vector", ^{
      size_t hash0 = std::hash<CGFloats>()({1, 2});
      size_t hash1 = std::hash<CGFloats>()({1, 2});
      expect(hash0).to.equal(hash1);
    });
  });

  context(@"hashing std::array", ^{
    it(@"should hash std::array", ^{
      size_t hash0 = std::hash<std::array<CGFloat, 3>>()({{1, 2, 3}});
      size_t hash1 = std::hash<std::array<CGFloat, 3>>()({{1, 2, 3}});
      expect(hash0).to.equal(hash1);
    });
  });
});

context(@"structs", ^{
  it(@"should hash CGPoint", ^{
    size_t hash0 = std::hash<CGPoint>()(CGPointMake(0.5, 1.7));
    size_t hash1 = std::hash<CGPoint>()(CGPointMake(0.5, 1.7));
    expect(hash0).to.equal(hash1);
  });

  it(@"should hash CGSize", ^{
    size_t hash0 = std::hash<CGSize>()(CGSizeMake(0.5, 1.7));
    size_t hash1 = std::hash<CGSize>()(CGSizeMake(0.5, 1.7));
    expect(hash0).to.equal(hash1);
  });

  it(@"should hash CGRect", ^{
    size_t hash0 = std::hash<CGRect>()(CGRectMake(0.5, 1.7, 0.5, 1.7));
    size_t hash1 = std::hash<CGRect>()(CGRectMake(0.5, 1.7, 0.5, 1.7));
    expect(hash0).to.equal(hash1);
  });

  it(@"should hash CGAffineTransform", ^{
    size_t hash0 = std::hash<CGAffineTransform>()(CGAffineTransformMake(1, 2, 3, 4, 5, 6));
    size_t hash1 = std::hash<CGAffineTransform>()(CGAffineTransformMake(1, 2, 3, 4, 5, 6));
    expect(hash0).to.equal(hash1);
  });
});

context(@"Objective-C objects", ^{
  it(@"should hash NSArray", ^{
    size_t hash0 = std::hash<NSArray *>()(@[@"foo"]);
    size_t hash1 = std::hash<NSArray *>()(@[@"foo"]);
    expect(hash0).to.equal(hash1);
  });

  it(@"should hash NSDate", ^{
    size_t hash0 = std::hash<NSDate *>()([NSDate distantPast]);
    size_t hash1 = std::hash<NSDate *>()([NSDate distantPast]);
    expect(hash0).to.equal(hash1);
  });

  it(@"should hash NSDictionary", ^{
    size_t hash0 = std::hash<NSDictionary *>()(@{@"foo": @7});
    size_t hash1 = std::hash<NSDictionary *>()(@{@"foo": @7});
    expect(hash0).to.equal(hash1);
  });

  it(@"should hash NSString", ^{
    size_t hash0 = std::hash<NSString *>()(@"foo");
    size_t hash1 = std::hash<NSString *>()(@"foo");
    expect(hash0).to.equal(hash1);
  });

  it(@"should hash NSValue", ^{
    size_t hash0 = std::hash<NSValue *>()($(CGPointMake(1, 2)));
    size_t hash1 = std::hash<NSValue *>()($(CGPointMake(1, 2)));
    expect(hash0).to.equal(hash1);
  });
});

SpecEnd
