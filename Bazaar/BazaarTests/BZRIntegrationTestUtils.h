// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

@class BZRProduct, BZRReceiptValidationStatus;

NS_ASSUME_NONNULL_BEGIN

/// Stubs \c dataMock to return encoded \c receiptString when getting the receipt data.
void BZRStubDataMockReceiptData(NSData *dataMock, NSString *receiptString);

/// Stubs url requests that contain the string \c @"validateReceipt" to return the serialization of
/// \c receiptValidationStatus.
/// After using this method, one should call \c [OHHTTPStubs removeAllStubs].
void BZRStubHTTPClientToReturnReceiptValidationStatus
    (BZRReceiptValidationStatus *receiptValidationStatus);

/// Stubs consecutive url requests that contain the string \c @"validateReceipt" to return the
/// serialization of the statuses in \c receiptValidationStatusArray in the order of the array,
/// if there are not enough statuses in the array, the last status will repeat in all
/// consecutive requests.
/// After using this method, one should call \c [OHHTTPStubs removeAllStubs].
void BZRStubHTTPClientToReturnReceiptValidationStatusesInOrder
    (NSArray<BZRReceiptValidationStatus *> *receiptValidationStatusArray);

/// Stubs \c fileManager to return the serialization of the \c products array when reading from
/// the \c filepath.
void BZRStubFileManagerToReturnJSONWithProducts(NSFileManager *fileManager, NSString *filepath,
    NSArray<BZRProduct *> *products);

/// Stubs \c fileManager to return serialization of a product with \c productIdentifier when
/// reading from the \c filepath.
void BZRStubFileManagerToReturnJSONWithASingleProduct(NSFileManager *fileManager,
    NSString *filepath, NSString *productIdentifier);

NS_ASSUME_NONNULL_END
