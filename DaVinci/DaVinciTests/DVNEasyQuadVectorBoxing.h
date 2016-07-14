// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTQuad.h>

/// Converts the given \c quads into the corresponding \c lt::Quad objects and returns them.
std::vector<lt::Quad> DVNConvertedQuadsFromQuads(NSArray<LTQuad *> *quads);

/// Converts the given \c quads into the corresponding \c LTQuad objects and returns them.
NSArray<LTQuad *> *DVNConvertedQuadsFromQuads(const std::vector<lt::Quad> &quads);
