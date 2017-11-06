// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTQuad.h>

NS_ASSUME_NONNULL_BEGIN

/// Converts the given \c quads into the corresponding \c lt::Quad objects and returns them.
std::vector<lt::Quad> DVNConvertedQuadsFromQuads(NSArray<LTQuad *> *quads);

/// Converts the given boxed \c quads into the corresponding \c lt::Quad objects and returns them.
std::vector<lt::Quad> DVNConvertedQuadsFromBoxedQuads(NSArray<NSValue *> *quads);

/// Converts the given \c quads into the corresponding \c LTQuad objects and returns them.
NSArray<LTQuad *> *DVNConvertedQuadsFromQuads(const std::vector<lt::Quad> &quads);

/// Converts the given \c quads into the corresponding boxed \c lt::Quad objects and returns them.
NSArray<NSValue *> *DVNConvertedBoxedQuadsFromQuads(const std::vector<lt::Quad> &quads);

NS_ASSUME_NONNULL_END
