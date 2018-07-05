// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

NS_ASSUME_NONNULL_BEGIN

/// Key backing a reversible transformer that converts an \c NSString URL representation to its
/// corresponding \c NSURL and vice versa. \c nil is converted to \c nil, in both directions.
///
/// The input to the forward transformer must be an \c NSString describing a URL. The string may
/// contain unicode and characters that must be percent encoded. The output will contain percent
/// encoded characters only for characters which are in \c URLQueryAllowedCharacterSet.
///
/// The input to the reverse transformer must an \c NSURL.
///
/// If the input is not one of these types or the specific type conditions fail, \c nil will
/// be returned and an error will be logged for the forward transformer, and assertion exception for
/// the reverse transformer.
extern NSString * const kPTNURLValueTransformer;

NS_ASSUME_NONNULL_END
