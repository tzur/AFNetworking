// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTQuad.h>

@protocol LTSampleValues;

namespace dvn {

  /// Struct representing quadrilateral geometry constructed from \c id<LTSampleValues> objects.
  struct GeometryValues {
  public:
    /// Initializes with the given \c quads, \c indices and \c samples. The \c size() of the given
    /// \c quads must equal both the \c size() of the given \c indices and the \c size() of the
    /// \c sampledParametricValues of the given \c samples.
    explicit GeometryValues(const std::vector<lt::Quad> &quads,
                            const std::vector<NSUInteger> &indices,
                            id<LTSampleValues> samples);

    /// Returns a hash value for this instance.
    size_t hash() const;

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
