// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTCommonDrawableShapeStructs.h"

#import "LTGLKitExtensions.h"

BOOL LTAreVerticesEqual(const LTCommonDrawableShapeVertex &v0,
                        const LTCommonDrawableShapeVertex &v1) {
  return !memcmp(&v0, &v1, sizeof(LTCommonDrawableShapeVertex));
}

SpecBegin(LTCommonDrawableShapeStructs)

__block LTCommonDrawableShapeVertices shadowVertices;
__block LTCommonDrawableShapeVertices strokeVertices;

beforeEach(^{
  shadowVertices.clear();
  strokeVertices.clear();
});

context(@"adding vertices", ^{
  __block LTCommonDrawableShapeVertex vertex;

  beforeEach(^{
    vertex.position = LTVector2::ones();
    vertex.offset = LTVector2::ones() * 2;
    vertex.lineBounds = LTVector4::ones();
    vertex.shadowBounds = LTVector4::ones() * 2;
    vertex.color = LTVector4::ones() * 0.5;
    vertex.shadowColor = LTVector4::ones() * 0.25;
  });

  it(@"should add shadow vertex", ^{
    LTAddShadowVertex(vertex, &shadowVertices);
    expect(LTAreVerticesEqual(vertex, shadowVertices.front())).to.beFalsy();
    expect(shadowVertices.front().color).to.equal(LTVector4::zeros());

    vertex.color = LTVector4::zeros();
    LTAddShadowVertex(vertex, &shadowVertices);
    expect(LTAreVerticesEqual(vertex, shadowVertices.back())).to.beTruthy();
    expect(shadowVertices.size()).to.equal(2);
  });

  it(@"should assert when adding shadow vertex if vector is nil", ^{
    expect(^{
      LTAddShadowVertex(vertex, nil);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should add stroke vertex", ^{
    LTAddStrokeVertex(vertex, &strokeVertices);
    expect(LTAreVerticesEqual(vertex, strokeVertices.front())).to.beFalsy();
    expect(strokeVertices.front().shadowColor).to.equal(LTVector4::zeros());

    vertex.shadowColor = LTVector4::zeros();
    LTAddStrokeVertex(vertex, &strokeVertices);
    expect(LTAreVerticesEqual(vertex, strokeVertices.back())).to.beTruthy();
    expect(strokeVertices.size()).to.equal(2);
  });

  it(@"should assert when adding stroke vertex if vector is nil", ^{
    expect(^{
      LTAddStrokeVertex(vertex, nil);
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"adding segments", ^{
  __block LTCommonDrawableShapeSegment segment;

  beforeEach(^{
    for (LTCommonDrawableShapeVertex &vertex : segment.v) {
      vertex.offset = LTVector2::ones() * 2;
      vertex.lineBounds = LTVector4::ones();
      vertex.shadowBounds = LTVector4::ones() * 2;
      vertex.color = LTVector4::ones() * 0.5;
      vertex.shadowColor = LTVector4::ones() * 0.25;
    }
    segment.src0.position = LTVector2(0, 0);
    segment.src1.position = LTVector2(0, 1);
    segment.dst0.position = LTVector2(1, 0);
    segment.dst1.position = LTVector2(1, 1);
  });

  it(@"should add segment with shadow vertices", ^{
    LTAddSegment(segment, &strokeVertices, &shadowVertices);
    expect(strokeVertices.size()).to.equal(6);
    expect(shadowVertices.size()).to.equal(6);
    for (NSUInteger i = 0; i < 6; ++i) {
      // beCloseToGLKVector is used since 'equal' matcher doesn't work properly for LTVector2.
      expect(strokeVertices[i].offset).to.beCloseToGLKVector(segment.src0.offset);
      expect(shadowVertices[i].offset).to.beCloseToGLKVector(segment.src0.offset);
      expect(strokeVertices[i].lineBounds).to.equal(segment.src0.lineBounds);
      expect(shadowVertices[i].lineBounds).to.equal(segment.src0.lineBounds);
      expect(strokeVertices[i].shadowBounds).to.equal(segment.src0.shadowBounds);
      expect(shadowVertices[i].shadowBounds).to.equal(segment.src0.shadowBounds);
      expect(strokeVertices[i].color).to.equal(segment.src0.color);
      expect(shadowVertices[i].color).to.equal(LTVector4::zeros());
      expect(strokeVertices[i].shadowColor).to.equal(LTVector4::zeros());
      expect(shadowVertices[i].shadowColor).to.equal(segment.src0.shadowColor);
      expect(strokeVertices[i].position).to.beCloseToGLKVector(shadowVertices[i].position);
    }
    expect(strokeVertices[0].position).to.beCloseToGLKVector(segment.src0.position);
    expect(strokeVertices[1].position).to.beCloseToGLKVector(segment.src1.position);
    expect(strokeVertices[2].position).to.beCloseToGLKVector(segment.dst0.position);
    expect(strokeVertices[3].position).to.beCloseToGLKVector(segment.src1.position);
    expect(strokeVertices[4].position).to.beCloseToGLKVector(segment.dst1.position);
    expect(strokeVertices[5].position).to.beCloseToGLKVector(segment.dst0.position);
  });

  it(@"should add segment without shadow vertices", ^{
    LTAddSegment(segment, &strokeVertices, nil);
    expect(strokeVertices.size()).to.equal(6);
    for (const LTCommonDrawableShapeVertex &vertex : strokeVertices) {
      // beCloseToGLKVector is used since 'equal' matcher doesn't work properly for LTVector2.
      expect(vertex.offset).to.beCloseToGLKVector(segment.src0.offset);
      expect(vertex.lineBounds).to.equal(segment.src0.lineBounds);
      expect(vertex.shadowBounds).to.equal(segment.src0.shadowBounds);
      expect(vertex.color).to.equal(segment.src0.color);
      expect(vertex.shadowColor).to.equal(LTVector4::zeros());
    }
    expect(strokeVertices[0].position).to.beCloseToGLKVector(segment.src0.position);
    expect(strokeVertices[1].position).to.beCloseToGLKVector(segment.src1.position);
    expect(strokeVertices[2].position).to.beCloseToGLKVector(segment.dst0.position);
    expect(strokeVertices[3].position).to.beCloseToGLKVector(segment.src1.position);
    expect(strokeVertices[4].position).to.beCloseToGLKVector(segment.dst1.position);
    expect(strokeVertices[5].position).to.beCloseToGLKVector(segment.dst0.position);
  });

  it(@"should assert when adding segment if stroke vector is nil", ^{
    expect(^{
      LTAddSegment(segment, nil, &shadowVertices);
    }).to.raise(NSInvalidArgumentException);
  });
});

SpecEnd
