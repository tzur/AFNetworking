// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTQuad.h>

#import <LTEngine/LTSampleValues.h>
#import <LTKit/LTHashExtensions.h>

namespace dvn {

  /// Struct representing quadrilateral geometry constructed from \c id<LTSampleValues> objects.
  struct GeometryValues {
  public:
    /// Returns an empty struct.
    GeometryValues() noexcept : _quads({}), _indices({}),
        _samples([[LTSampleValues alloc] initWithSampledParametricValues:{} mapping:nil]) {}

    /// Initializes with the given \c quads, \c indices and \c samples. The \c size() of the given
    /// \c quads must equal to the \c size() of the given \c indices.
    explicit GeometryValues(const std::vector<lt::Quad> &quads,
                            const std::vector<NSUInteger> &indices,
                            id<LTSampleValues> samples);

    /// Returns the quads constructed from the \c samples.
    inline const std::vector<lt::Quad> &quads() const {
      return _quads;
    }

    /// Returns the indices of \c samples used to construct the corresponding \c quads provided by
    /// this instance.
    inline const std::vector<NSUInteger> &indices() const {
      return _indices;
    }

    /// Returns the samples used to construct the \c quads provided by this instance.
    inline id<LTSampleValues> samples() const {
      return _samples;
    }

  private:
    /// Quads constructed from the \c samples.
    std::vector<lt::Quad> _quads;

    /// Indices of \c samples used to construct the corresponding \c quads provided by this
    /// instance.
    std::vector<NSUInteger> _indices;

    /// Samples used to construct the \c quads provided by this instance.
    id<LTSampleValues> _samples;
  };

} // namespace dvn

template <>
struct ::std::hash<dvn::GeometryValues> {
  inline size_t operator()(const dvn::GeometryValues &values) const {
    return std::hash<std::vector<lt::Quad>>()(values.quads()) ^
        std::hash<std::vector<NSUInteger>>()(values.indices()) ^ values.samples().hash;
  }
};

/// Returns \c true if \c lhs equals \c rhs.
bool operator==(const dvn::GeometryValues &lhs, const dvn::GeometryValues &rhs);

/// Returns \c true if \c lhs does not equal \c rhs.
bool operator!=(const dvn::GeometryValues &lhs, const dvn::GeometryValues &rhs);
