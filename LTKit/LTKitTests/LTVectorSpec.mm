// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTVector.h"

SpecBegin(LTVector)

context(@"LTVector2", ^{
  it(@"should initialize correctly", ^{
    LTVector2 v1;
    expect(v1.x).to.equal(0);
    expect(v1.y).to.equal(0);

    LTVector2 v2(1, 2);
    expect(v2.x).to.equal(1);
    expect(v2.y).to.equal(2);

    LTVector2 v3(CGPointMake(3, 4));
    expect(v3.x).to.equal(3);
    expect(v3.y).to.equal(4);

    LTVector2 v4(CGSizeMake(5, 6));
    expect(v4.x).to.equal(5);
    expect(v4.y).to.equal(6);
    
    LTVector2 v5(LTVector2(7, 8));
    expect(v5.x).to.equal(7);
    expect(v5.y).to.equal(8);
    
    LTVector2 v6(9);
    expect(v6.x).to.equal(9);
    expect(v6.y).to.equal(9);
  });

  it(@"should cast to LTVector2", ^{
    LTVector2 ltVector(5, 7);
    LTVector2 glkVector(ltVector);

    expect(ltVector.x).to.equal(glkVector.x);
    expect(ltVector.y).to.equal(glkVector.y);
  });

  it(@"should cast to CGPoint", ^{
    LTVector2 vector(1, 2);
    CGPoint point(vector);

    expect(point.x).to.equal(vector.x);
    expect(point.y).to.equal(vector.y);
  });

  it(@"should cast to CGSize", ^{
    LTVector2 vector(1, 2);
    CGSize size(vector);
    
    expect(size.width).to.equal(vector.x);
    expect(size.height).to.equal(vector.y);
  });
  
  it(@"should perform math operations correctly", ^{
    LTVector2 v1(10, 8);
    LTVector2 v2(5, 4);

    expect(v1 + v2).to.equal(LTVector2(15, 12));
    expect(v1 - v2).to.equal(LTVector2(5, 4));
    expect(v1 * v2).to.equal(LTVector2(50, 32));
    expect(v1 * 2).to.equal(LTVector2(20, 16));
    expect(2 * v1).to.equal(LTVector2(20, 16));
    expect(v1 / v2).to.equal(LTVector2(2, 2));
    expect(v1 / 2).to.equal(LTVector2(5, 4));
    expect(80 / v1).to.equal(LTVector2(8, 10));
    expect(-v1).to.equal(LTVector2(-10, -8));
  });

  it(@"should perform equality correctly", ^{
    expect(LTVector2(1, 2) == LTVector2(1, 2)).to.beTruthy();
    expect(LTVector2(1, 3) == LTVector2(1, 2)).to.beFalsy();
    expect(LTVector2(1, 2) != LTVector2(1, 2)).to.beFalsy();
    expect(LTVector2(1, 3) != LTVector2(1, 2)).to.beTruthy();
    expect(LTVector2(1, 2) >= LTVector2(1, 2)).to.beTruthy();
    expect(LTVector2(1, 1) >= LTVector2(1, 2)).to.beFalsy();
    expect(LTVector2(1, 2) <= LTVector2(1, 2)).to.beTruthy();
    expect(LTVector2(1, 3) <= LTVector2(1, 2)).to.beFalsy();
  });

  it(@"should access rgb values correctly", ^{
    LTVector2 v(1, 2);
    v.r() = 5;
    v.g() = 8;
    expect(v).to.equal(LTVector2(5, 8));
  });
  
  it(@"should sum the vector components correctly", ^{
    LTVector2 v(1, 2);
    expect(v.sum()).to.equal(3);
  });

  it(@"should access data correctly", ^{
    LTVector2 v(1, 2);
    expect(v.data()[0]).to.equal(1);
    expect(v.data()[1]).to.equal(2);
  });

  context(@"std", ^{
    it(@"should return rounded vector", ^{
      LTVector2 v(1.3, 2.7);
      expect(std::round(v)).to.equal(LTVector2(1, 3));
    });

    it(@"should return minimal vector", ^{
      LTVector2 v1(1, 4);
      LTVector2 v2(2, 3);
      expect(std::min(v1, v2)).to.equal(LTVector2(1, 3));
    });

    it(@"should return minimal component", ^{
      expect(std::min(LTVector2(1, 7))).to.equal(1);
    });
  });

  context(@"conversions", ^{
    it(@"should convert from string", ^{
      NSString *value = @"(1.5, 2.5, 3)";
      LTVector3 vector = LTVector3FromString(value);
      expect(vector.x).to.equal(1.5);
      expect(vector.y).to.equal(2.5);
      expect(vector.z).to.equal(3);
    });

    it(@"should return zero vector on invalid string", ^{
      expect(LTVector2FromString(@"(1.5)")).to.equal(LTVector2());
      expect(LTVector2FromString(@"(1.5, 2.5")).to.equal(LTVector2());
      expect(LTVector2FromString(@"1.5, 2.5)")).to.equal(LTVector2());
      expect(LTVector2FromString(@"(3)")).to.equal(LTVector2());
      expect(LTVector2FromString(@"(a, 2)")).to.equal(LTVector2());
    });
  });
});

context(@"LTVector3", ^{
  it(@"should initialize correctly", ^{
    LTVector3 v1;
    expect(v1.x).to.equal(0);
    expect(v1.y).to.equal(0);
    expect(v1.z).to.equal(0);
    
    LTVector3 v2(1);
    expect(v2.x).to.equal(1);
    expect(v2.y).to.equal(1);
    expect(v2.z).to.equal(1);

    LTVector3 v3(1, 2, 3);
    expect(v3.x).to.equal(1);
    expect(v3.y).to.equal(2);
    expect(v3.z).to.equal(3);

    LTVector3 v4(LTVector3(3, 4, 5));
    expect(v4.x).to.equal(3);
    expect(v4.y).to.equal(4);
    expect(v4.z).to.equal(5);
  });

  it(@"should cast to LTVector3", ^{
    LTVector3 ltVector(5, 7, 9);
    LTVector3 glkVector(ltVector);

    expect(ltVector.x).to.equal(glkVector.x);
    expect(ltVector.y).to.equal(glkVector.y);
    expect(ltVector.z).to.equal(glkVector.z);
  });

  it(@"should perform math operations correctly", ^{
    LTVector3 v1(10, 8, 6);
    LTVector3 v2(5, 4, 2);

    expect(v1 + v2).to.equal(LTVector3(15, 12, 8));
    expect(v1 - v2).to.equal(LTVector3(5, 4, 4));
    expect(v1 * v2).to.equal(LTVector3(50, 32, 12));
    expect(v1 * 2).to.equal(LTVector3(20, 16, 12));
    expect(2 * v1).to.equal(LTVector3(20, 16, 12));
    expect(v1 / v2).to.equal(LTVector3(2, 2, 3));
    expect(v1 / 2).to.equal(LTVector3(5, 4, 3));
    expect(480 / v1).to.equal(LTVector3(48, 60, 80));
    expect(-v1).to.equal(LTVector3(-10, -8, -6));
  });

  it(@"should perform equality correctly", ^{
    expect(LTVector3(1, 2, 3) == LTVector3(1, 2, 3)).to.beTruthy();
    expect(LTVector3(1, 3, 3) == LTVector3(1, 2, 3)).to.beFalsy();
    expect(LTVector3(1, 2, 3) != LTVector3(1, 2, 3)).to.beFalsy();
    expect(LTVector3(1, 3, 3) != LTVector3(1, 2, 3)).to.beTruthy();
    expect(LTVector3(1, 2, 3) >= LTVector3(1, 2, 4)).to.beFalsy();
    expect(LTVector3(1, 2, 3) >= LTVector3(1, 2, 3)).to.beTruthy();
    expect(LTVector3(1, 2, 3) <= LTVector3(1, 2, 3)).to.beTruthy();
    expect(LTVector3(1, 3, 3) <= LTVector3(1, 2, 3)).to.beFalsy();
  });

  it(@"should access rgb values correctly", ^{
    LTVector3 v(1, 2, 3);
    v.r() = 5;
    v.g() = 8;
    v.b() = 2;
    expect(v).to.equal(LTVector3(5, 8, 2));
  });
  
  it(@"should sum the vector components correctly", ^{
    LTVector3 v(1, 2, 3);
    expect(v.sum()).to.equal(6);
  });

  it(@"should access data correctly", ^{
    LTVector3 v(1, 2, 3);
    expect(v.data()[0]).to.equal(1);
    expect(v.data()[1]).to.equal(2);
    expect(v.data()[2]).to.equal(3);
  });

  context(@"std", ^{
    it(@"should return rounded vector", ^{
      LTVector3 v(1.3, 2.7, 3.3);
      expect(std::round(v)).to.equal(LTVector3(1, 3, 3));
    });

    it(@"should return minimal vector", ^{
      LTVector3 v1(1, 4, 5);
      LTVector3 v2(2, 3, 4);
      expect(std::min(v1, v2)).to.equal(LTVector3(1, 3, 4));
    });

    it(@"should return minimal component", ^{
      expect(std::min(LTVector3(1, 7, -5))).to.equal(-5);
    });
  });

  context(@"conversions", ^{
    it(@"should convert from string", ^{
      NSString *value = @"(1.5, 2.5, 3)";
      LTVector3 vector = LTVector3FromString(value);
      expect(vector.x).to.equal(1.5);
      expect(vector.y).to.equal(2.5);
      expect(vector.z).to.equal(3);
    });

    it(@"should return zero vector on invalid string", ^{
      expect(LTVector3FromString(@"(1.5, 2.5)")).to.equal(LTVector3());
      expect(LTVector3FromString(@"(1.5, 2.5, 3")).to.equal(LTVector3());
      expect(LTVector3FromString(@"1.5, 2.5, 3)")).to.equal(LTVector3());
      expect(LTVector3FromString(@"(3, 4)")).to.equal(LTVector3());
      expect(LTVector3FromString(@"(a, 2, 4)")).to.equal(LTVector3());
    });
  });
});

context(@"LTVector4", ^{
  it(@"should initialize correctly", ^{
    LTVector4 v1;
    expect(v1.x).to.equal(0);
    expect(v1.y).to.equal(0);
    expect(v1.z).to.equal(0);
    expect(v1.w).to.equal(0);
    
    LTVector4 v2(1);
    expect(v2.x).to.equal(1);
    expect(v2.y).to.equal(1);
    expect(v2.z).to.equal(1);
    expect(v2.w).to.equal(1);

    LTVector4 v3(1, 2, 3, 4);
    expect(v3.x).to.equal(1);
    expect(v3.y).to.equal(2);
    expect(v3.z).to.equal(3);
    expect(v3.w).to.equal(4);

    LTVector4 v4(LTVector4(3, 4, 5, 6));
    expect(v4.x).to.equal(3);
    expect(v4.y).to.equal(4);
    expect(v4.z).to.equal(5);
    expect(v4.w).to.equal(6);
  });

  it(@"should cast to LTVector4", ^{
    LTVector4 ltVector(5, 7, 9, 11);
    LTVector4 glkVector(ltVector);

    expect(ltVector.x).to.equal(glkVector.x);
    expect(ltVector.y).to.equal(glkVector.y);
    expect(ltVector.z).to.equal(glkVector.z);
    expect(ltVector.w).to.equal(glkVector.w);
  });

  it(@"should perform math operations correctly", ^{
    LTVector4 v1(10, 8, 6, 12);
    LTVector4 v2(5, 4, 2, 6);

    expect(v1 + v2).to.equal(LTVector4(15, 12, 8, 18));
    expect(v1 - v2).to.equal(LTVector4(5, 4, 4, 6));
    expect(v1 * v2).to.equal(LTVector4(50, 32, 12, 72));
    expect(v1 * 2).to.equal(LTVector4(20, 16, 12, 24));
    expect(2 * v1).to.equal(LTVector4(20, 16, 12, 24));
    expect(v1 / v2).to.equal(LTVector4(2, 2, 3, 2));
    expect(v1 / 2).to.equal(LTVector4(5, 4, 3, 6));
    expect(480 / v1).to.equal(LTVector4(48, 60, 80, 40));
    expect(-v1).to.equal(LTVector4(-10, -8, -6, -12));
  });

  it(@"should perform equality correctly", ^{
    expect(LTVector4(1, 2, 3, 1) == LTVector4(1, 2, 3, 1)).to.beTruthy();
    expect(LTVector4(1, 3, 3, 1) == LTVector4(1, 2, 3, 1)).to.beFalsy();
    expect(LTVector4(1, 2, 3, 1) != LTVector4(1, 2, 3, 1)).to.beFalsy();
    expect(LTVector4(1, 3, 3, 1) != LTVector4(1, 2, 3, 1)).to.beTruthy();
  });

  it(@"should access rgb values correctly", ^{
    LTVector4 v(1, 2, 3, 4);
    v.r() = 5;
    v.g() = 8;
    v.b() = 2;
    v.a() = 12;
    expect(v).to.equal(LTVector4(5, 8, 2, 12));
  });

  it(@"should sum the vector components correctly", ^{
    LTVector4 v(1, 2, 3, 4);
    expect(v.sum()).to.equal(10);
  });

  it(@"should access data correctly", ^{
    LTVector4 v(1, 2, 3, 4);
    expect(v.data()[0]).to.equal(1);
    expect(v.data()[1]).to.equal(2);
    expect(v.data()[2]).to.equal(3);
    expect(v.data()[3]).to.equal(4);
  });

  context(@"std", ^{
    it(@"should return rounded vector", ^{
      LTVector4 v(1.3, 2.7, 3.3, -0.1);
      expect(std::round(v)).to.equal(LTVector4(1, 3, 3, 0));
    });

    it(@"should return minimal vector", ^{
      LTVector4 v1(1, 4, 5, 0);
      LTVector4 v2(2, 3, 4, -1);
      expect(std::min(v1, v2)).to.equal(LTVector4(1, 3, 4, -1));
    });

    it(@"should return minimal component", ^{
      expect(std::min(LTVector4(1, 7, -5, 100))).to.equal(-5);
    });
  });

  context(@"conversions", ^{
    it(@"should convert from string", ^{
      NSString *value = @"(1.5, 2.5, 3, 4)";
      LTVector4 vector = LTVector4FromString(value);
      expect(vector.x).to.equal(1.5);
      expect(vector.y).to.equal(2.5);
      expect(vector.z).to.equal(3);
      expect(vector.w).to.equal(4);
    });

    it(@"should return zero vector on invalid string", ^{
      expect(LTVector4FromString(@"(1.5, 2.5, 3)")).to.equal(LTVector4());
      expect(LTVector4FromString(@"(1.5, 2.5, 3, 4")).to.equal(LTVector4());
      expect(LTVector4FromString(@"1.5, 2.5, 3, 4)")).to.equal(LTVector4());
      expect(LTVector4FromString(@"(3, 4)")).to.equal(LTVector4());
      expect(LTVector4FromString(@"(a, 2, 3, 4)")).to.equal(LTVector4());
    });
  });
});

SpecEnd
