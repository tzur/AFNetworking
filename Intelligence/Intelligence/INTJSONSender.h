// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

/// Implemented by objects that can send any valid JSON record over the network. A sender may have
/// input limits regarding the amount of JSON records that can be sent in one batch which is defined
/// by \c maxRecordBatchSize or the byte count for an individual records, defined by
/// \c maxRecordSize. Trying to send JSON records that do not comply with the aforementioned
/// constraints yields an error.
@protocol INTJSONSender <NSObject>

/// Serializes JSON records and sends them over to an underlying service. Records must be include
/// JSON compliant types, and pass the <tt>-[NSJSONSerialization isValidJSONObject:]</tt> method.
/// The returned signal completes once the sending completes successfully or errs with:
///
/// 1. \c INTErrorCodeJSONRecordsSendFailed if sending fails due to network
/// errors.
/// 2. \c INTErrorCodeInvalidJSONRecords if the \c records cannot be ingested by the receiver
/// due to a wrong JSON format or one of the records exceeding \c maxRecordSize.
/// 3. \c INTErrorCodeJSONBatchSizeTooLarge if the amount of \c records exceeding
/// \c maxRecordBatchSize.
- (RACSignal *)sendRecords:(NSArray<NSDictionary<NSString *, id> *> *)records;

/// Maximal amount of records the sender can send in one batch to its underlying service.
@property (readonly, nonatomic) NSUInteger maxRecordBatchSize;

/// Maximal record size in bytes the underlying service of the sender can ingest.
@property (readonly, nonatomic) NSUInteger maxRecordSize;

@end

NS_ASSUME_NONNULL_END
