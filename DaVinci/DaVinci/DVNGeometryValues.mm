// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNGeometryValues.h"

#import <LTEngine/LTSampleValues.h>

namespace dvn {

GeometryValues::GeometryValues(const std::vector<lt::Quad> &quads,
                               const std::vector<NSUInteger> &indices,
                               id<LTSampleValues> samples) {
  LTParameterAssert(quads.size() == indices.size(),
                    @"Number (%lu) of quads must equal number (%lu) of indices",
                    (unsigned long)quads.size(),  (unsigned long)indices.size());
  LTParameterAssert(quads.size() == samples.sampledParametricValues.size(),
                    @"Number (%lu) of quads must equal number (%lu) of sampled parametric values",
                    (unsigned long)quads.size(),
                    (unsigned long)samples.sampledParametricValues.size());
  _quads = quads;
  _indices = indices;
  _samples = samples;
}

size_t GeometryValues::hash() const {
  return std::hash<std::vector<lt::Quad>>()(_quads) ^
      std::hash<std::vector<NSUInteger>>()(_indices) ^ _samples.hash;
}

} // namespace dvn
