// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTriangle.h"

SpecBegin(LTTriangle)

__block CGPoint v0;
__block CGPoint v1;
__block CGPoint v2;

beforeEach(^{
  v0 = CGPointMake(0, 0);
  v1 = CGPointMake(1, 0);
  v2 = CGPointMake(1, 1);
});

context(@"initializers", ^{
  it(@"should default initialize to the null triangle", ^{
    lt::Triangle triangle;
    LTTriangleCorners corners{{triangle.v0(), triangle.v1(), triangle.v2()}};
    expect(CGPointIsNull(corners[0])).to.beTruthy();
    expect(CGPointIsNull(corners[1])).to.beTruthy();
    expect(CGPointIsNull(corners[2])).to.beTruthy();
  });

  it(@"should initialize with corners", ^{
    lt::Triangle triangle(v0, v1, v2);
    LTTriangleCorners corners{{triangle.v0(), triangle.v1(), triangle.v2()}};
    expect(corners[0]).to.equal(v0);
    expect(corners[1]).to.equal(v1);
    expect(corners[2]).to.equal(v2);
  });

  it(@"should initialize with corner array", ^{
    LTTriangleCorners corners{{v0, v1, v2}};
    lt::Triangle triangle(corners);
    LTTriangleCorners retrievedCorners{{triangle.v0(), triangle.v1(), triangle.v2()}};
    expect(retrievedCorners[0]).to.equal(v0);
    expect(retrievedCorners[1]).to.equal(v1);
    expect(retrievedCorners[2]).to.equal(v2);
  });

  it(@"should set all corners to CGPointNull when initializing with at least one null corner", ^{
    lt::Triangle triangle(v0, v1, CGPointNull);
    LTTriangleCorners corners{{triangle.v0(), triangle.v1(), triangle.v2()}};
    expect(CGPointIsNull(corners[0])).to.beTruthy();
    expect(CGPointIsNull(corners[1])).to.beTruthy();
    expect(CGPointIsNull(corners[2])).to.beTruthy();
  });
});

context(@"order", ^{
  it(@"should return a flipped copy", ^{
    LTTriangleCorners corners = {{v0, v1, v2}};
    lt::Triangle triangle = lt::Triangle(corners).flipped();
    LTTriangleCorners retrievedCorners{{triangle.v0(), triangle.v1(), triangle.v2()}};
    expect(retrievedCorners[0]).to.equal(v2);
    expect(retrievedCorners[1]).to.equal(v1);
    expect(retrievedCorners[2]).to.equal(v0);
  });
});

context(@"point inclusion", ^{
  it(@"should correctly compute point inclusion for the null triangle", ^{
    expect(lt::Triangle().containsPoint(CGPointZero)).to.beFalsy();
  });

  it(@"should correctly compute point inclusion for triangle with coinciding corners", ^{
    CGPoint point = CGPointMake(7, 8.5);
    LTTriangleCorners corners{{point, point, point}};
    lt::Triangle triangle(corners);
    expect(triangle.containsPoint(point)).to.beTruthy();
    expect(triangle.containsPoint(CGPointZero)).to.beFalsy();
  });

  it(@"should correctly compute point inclusion for triangle with collinear corners", ^{
    LTTriangleCorners corners{{CGPointZero, CGPointMake(1, 1), CGPointMake(2, 2)}};
    lt::Triangle triangle(corners);
    expect(triangle.containsPoint(CGPointMake(0.5, 0.5))).to.beTruthy();
    expect(triangle.containsPoint(CGPointMake(3, 3))).to.beFalsy();
    expect(triangle.containsPoint(CGPointMake(0.5, 0))).to.beFalsy();

    corners = {{CGPointZero, CGPointZero, CGPointMake(2, 2)}};
    triangle = lt::Triangle(corners);
    expect(triangle.containsPoint(CGPointMake(0.5, 0.5))).to.beTruthy();
    expect(triangle.containsPoint(CGPointMake(3, 3))).to.beFalsy();
    expect(triangle.containsPoint(CGPointMake(0.5, 0))).to.beFalsy();
  });

  context(@"non-degenerate triangles", ^{
    it(@"should correctly compute point inclusion for triangle with clockwise corners", ^{
      LTTriangleCorners corners{{v0, v1, v2}};
      lt::Triangle triangle(corners);
      expect(triangle.containsPoint(v0)).to.beTruthy();
      expect(triangle.containsPoint((v0 + v1) / 2)).to.beTruthy();
      expect(triangle.containsPoint(v1)).to.beTruthy();
      expect(triangle.containsPoint((v0 + v2) / 2 + CGPointMake(-0.125, 0))).to.beFalsy();
      expect(triangle.containsPoint(v2)).to.beTruthy();
      expect(triangle.containsPoint(CGPointMake(0, 1))).to.beFalsy();
    });

    it(@"should correctly compute point inclusion for triangle with counter-clockwise corners", ^{
      LTTriangleCorners corners{{v2, v1, v0}};
      lt::Triangle triangle(corners);
      expect(triangle.containsPoint(v0)).to.beTruthy();
      expect(triangle.containsPoint((v0 + v1) / 2)).to.beTruthy();
      expect(triangle.containsPoint(v1)).to.beTruthy();
      expect(triangle.containsPoint((v0 + v2) / 2 + CGPointMake(-0.125, 0))).to.beFalsy();
      expect(triangle.containsPoint(v2)).to.beTruthy();
      expect(triangle.containsPoint(CGPointMake(0, 1))).to.beFalsy();
    });
  });
});

context(@"equality", ^{
  it(@"should consider two triangles equal if their non-permutated corners() are equal", ^{
    LTTriangleCorners corners{{v0, v1, v2}};
    expect(lt::Triangle(corners) == lt::Triangle(corners)).to.beTruthy();

    LTTriangleCorners permutatedCorners{{v1, v2, v0}};
    expect(lt::Triangle(corners) == lt::Triangle(permutatedCorners)).to.beFalsy();
  });

  it(@"should consider two triangles inequal if their corners() are inequal", ^{
    LTTriangleCorners corners{{v0, v1, v2}};
    expect(lt::Triangle(corners) != lt::Triangle(corners)).to.beFalsy();

    LTTriangleCorners permutatedCorners{{v1, v2, v0}};
    expect(lt::Triangle(corners) != lt::Triangle(permutatedCorners)).to.beTruthy();
  });
});

context(@"properties", ^{
  context(@"area", ^{
    it(@"should return NAN as area of a null triangle", ^{
      expect(lt::Triangle().area()).to.equal(NAN);
    });

    it(@"should return 0 as area of a point triangle", ^{
      CGPoint point = CGPointMake(1, 1);
      LTTriangleCorners corners{{point, point, point}};
      expect(lt::Triangle(corners).area()).to.equal(0);
    });

    it(@"should return 0 as area of a collinear triangle", ^{
      LTTriangleCorners corners{{CGPointZero, CGPointMake(1, 1), CGPointMake(2, 2)}};
      expect(lt::Triangle(corners).area()).to.equal(0);
    });

    it(@"should return the correct area of a triangle with corners in clockwise order", ^{
      LTTriangleCorners corners{{v0, v1, v2}};
      expect(lt::Triangle(corners).area()).to.equal(0.5);
    });

    it(@"should return the correct area of a triangle with corners in counter-clockwise order", ^{
      LTTriangleCorners corners{{v2, v1, v0}};
      expect(lt::Triangle(corners).area()).to.equal(0.5);
    });
  });

  context(@"corners", ^{
    it(@"should return the correct corners", ^{
      LTTriangleCorners corners{{v0, v1, v2}};
      expect(lt::Triangle(corners).corners() == corners).to.beTruthy();
    });
  });

  context(@"type", ^{
    it(@"should return correct type of a null triangle", ^{
      expect(lt::Triangle().type()).to.equal(lt::Triangle::Type::Null);
    });

    it(@"should return correct type of a point triangle", ^{
      CGPoint point = CGPointMake(1, 1);
      LTTriangleCorners corners{{point, point, point}};
      expect(lt::Triangle(corners).type()).to.equal(lt::Triangle::Type::Point);
    });

    it(@"should return correct type of a collinear triangle", ^{
      LTTriangleCorners corners{{CGPointZero, CGPointMake(1, 1), CGPointMake(2, 2)}};
      expect(lt::Triangle(corners).type()).to.equal(lt::Triangle::Type::Collinear);
    });

    it(@"should return correct type of a triangle with corners in clockwise order", ^{
      LTTriangleCorners corners{{v0, v1, v2}};
      expect(lt::Triangle(corners).type()).to.equal(lt::Triangle::Type::Clockwise);
    });

    it(@"should return correct type of a triangle with corners in counter-clockwise order", ^{
      LTTriangleCorners corners{{v2, v1, v0}};
      expect(lt::Triangle(corners).type()).to.equal(lt::Triangle::Type::CounterClockwise);
    });
  });
});

context(@"std specializations", ^{
  it(@"should compute a correct hash value", ^{
    LTTriangleCorners corners{{v0, v1, v2}};
    lt::Triangle triangle0(corners);
    lt::Triangle triangle1(corners);
    expect(std::hash<lt::Triangle>()(triangle0)).to.equal(std::hash<lt::Triangle>()(triangle1));
  });
});

SpecEnd
