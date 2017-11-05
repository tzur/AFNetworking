// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

@class SPXBenefitAxisValue, SPXBaseProductAxisValue;

@protocol SPXProductAxisValue;

NS_ASSUME_NONNULL_BEGIN

/// Value class describing a specific product in the products matrix.
@interface SPXProductDescriptor : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initialize with \c indentifier, \c baseProductValues and \c benefitValues.
- (instancetype)initWithIdentifier:(NSString *)identifier
                 baseProductValues:(NSSet<SPXBaseProductAxisValue *> *)baseProductValues
                     benefitValues:(NSSet<SPXBenefitAxisValue *> *)benefitValues
    NS_DESIGNATED_INITIALIZER;

/// Uniquely identifies the product.
@property (readonly, nonatomic) NSString *identifier;

/// Values for base product axis.
@property (readonly, nonatomic) NSSet<SPXBaseProductAxisValue *> *baseProductValues;

/// Values for benefit axis.
@property (readonly, nonatomic) NSSet<SPXBenefitAxisValue *> *benefitValues;

@end

NS_ASSUME_NONNULL_END
