// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTHashExtensions.h"

SpecBegin(LTHashExtensions)

context(@"hashing with unordered_map", ^{
  it(@"should hash std::pair", ^{
    typedef std::pair<int, bool> LTTestPair;
    const std::unordered_map<LTTestPair, int, lt::hash<LTTestPair>> map{
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
    const std::unordered_map<LTTestTuple, int, lt::hash<LTTestTuple>> map{
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
    size_t hash0 = lt::hash<CGFloats>()({1, 2});
    size_t hash1 = lt::hash<CGFloats>()({1, 2});
    expect(hash0).to.equal(hash1);
  });
});

SpecEnd
