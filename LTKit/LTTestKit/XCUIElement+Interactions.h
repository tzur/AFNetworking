// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

/// Category to enrich the XCUIElement with UI interactions to use in UI tests.
@interface XCUIElement (Interactions)

/// Emulates pan gesture from the offset \c normalizedStart to the offset \c normalizedEnd. The
/// input offsets are multiplied by the size of this element’s frame and added to its origin. For
/// example in order to give the offset of the center of this element give:
/// @code
/// CGVectorMake(0.5, 0.5);
/// @endcode
/// If this element isn't in the view hierarchy a test failure will be triggered. If
/// \c normalizedStart is not visible does nothing. If \c normalizedEnd is not visible, pan until
/// visibility edge.
- (void)lt_panFromOffset:(CGVector)normalizedStart toOffset:(CGVector)normalizedEnd;

@end

NS_ASSUME_NONNULL_END
