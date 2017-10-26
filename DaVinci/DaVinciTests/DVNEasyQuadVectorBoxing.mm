// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNEasyQuadVectorBoxing.h"

#import <LTEngine/NSValue+LTQuad.h>

NS_ASSUME_NONNULL_BEGIN

std::vector<lt::Quad> DVNConvertedQuadsFromQuads(NSArray<LTQuad *> *quads) {
  std::vector<lt::Quad> convertedQuads;
  convertedQuads.reserve(quads.count);

  for (LTQuad *quad in quads) {
    convertedQuads.push_back(lt::Quad(quad.corners));
  }

  return convertedQuads;
}

std::vector<lt::Quad> DVNConvertedQuadsFromBoxedQuads(NSArray<NSValue *> *quads) {
  std::vector<lt::Quad> convertedQuads;
  convertedQuads.reserve(quads.count);

  for (NSValue *quad in quads) {
    convertedQuads.push_back(lt::Quad([quad LTQuadValue]));
  }

  return convertedQuads;
}

NSArray<LTQuad *> *DVNConvertedQuadsFromQuads(const std::vector<lt::Quad> &quads) {
  NSMutableArray<LTQuad *> *convertedQuads = [NSMutableArray arrayWithCapacity:quads.size()];

  for (const lt::Quad &quad : quads) {
    [convertedQuads addObject:[[LTQuad alloc] initWithCorners:quad.corners()]];
  }

  return [convertedQuads copy];
}

NSArray<NSValue *> *DVNConvertedBoxedQuadsFromQuads(const std::vector<lt::Quad> &quads) {
  NSMutableArray<NSValue *> *convertedQuads = [NSMutableArray arrayWithCapacity:quads.size()];

  for (const lt::Quad &quad : quads) {
    [convertedQuads addObject:[NSValue valueWithLTQuad:quad]];
  }

  return [convertedQuads copy];
}

NS_ASSUME_NONNULL_END
