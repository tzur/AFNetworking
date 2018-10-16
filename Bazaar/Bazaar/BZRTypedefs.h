// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

@class BZRProduct, BZRReceiptValidationStatus;

/// Maps product identifiers to products.
typedef NSDictionary<NSString *, BZRProduct *> BZRProductDictionary;

/// Collection of \c BZRProducts.
typedef NSArray<BZRProduct *> BZRProductList;

/// Maps product application bundle ID to receipt validation status.
typedef NSDictionary<NSString *, BZRReceiptValidationStatus *> BZRMultiAppReceiptValidationStatus;
