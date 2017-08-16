// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

NS_ASSUME_NONNULL_BEGIN

/// Key backing a reversible transformer that converts an \c NSString URL representation to its
/// corresponding \c NSURL and vice versa.
///
/// The input to the forward transformer must be an \c NSString describing a URL. The string may
/// contain unicode and characters that must be percent encoded. The output will contain percent
/// encoded characters only for characters which are in \c URLQueryAllowedCharacterSet.
///
/// The input to the reverse transformer must an \c NSURL.
///
/// If the input is \c nil, not one of these types or the specific type conditions fail, \c nil will
/// be returned and the error will be logged.
extern NSString * const kPTNURLValueTransformer;

NS_ASSUME_NONNULL_END
