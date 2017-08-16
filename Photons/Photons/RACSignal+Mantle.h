// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

NS_ASSUME_NONNULL_BEGIN

/// Category augmenting the \c RACSignal class with Mantle based operators.
@interface RACSignal (Mantle)

/// Parses a JSON \c NSDictionary object sent by the reciever into a \c MTLModel<MTLJSONSerializing>
/// subclass of the given \c modelClass and completes. Errs with
/// \c PTNErrorCodeParseJSONDictionaryFailed code if parsing has failed.
- (RACSignal *)ptn_parseDictionaryWithClass:(Class)modelClass;

@end

NS_ASSUME_NONNULL_END
