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

} // namespace dvn

bool operator==(const dvn::GeometryValues &lhs, const dvn::GeometryValues &rhs) {
  return lhs.quads() == rhs.quads() && lhs.indices() == rhs.indices() &&
  [lhs.samples() isEqual:rhs.samples()];
}

bool operator!=(const dvn::GeometryValues &lhs, const dvn::GeometryValues &rhs) {
  return !(lhs == rhs);
}
