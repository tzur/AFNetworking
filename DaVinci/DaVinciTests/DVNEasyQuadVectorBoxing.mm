// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNEasyQuadVectorBoxing.h"

std::vector<lt::Quad> DVNConvertedQuadsFromQuads(NSArray<LTQuad *> *quads) {
  std::vector<lt::Quad> convertedQuads;
  convertedQuads.reserve(quads.count);

  for (LTQuad *quad in quads) {
    convertedQuads.push_back(lt::Quad(quad.corners));
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
