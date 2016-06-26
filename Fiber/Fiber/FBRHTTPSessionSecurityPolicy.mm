// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPSessionSecurityPolicy.h"

#import "FBRCompare.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBRHTTPSessionSecurityPolicy

+ (instancetype)standardSecurityPolicy {
  return [[self alloc] initWithValidationMode:FBRCertificateValidationModeStandard
                           pinnedCertificates:nil];
}

+ (instancetype)securityPolicyWithPinnedCertificates:(NSSet<NSData *> *)certificates {
  return [[self alloc] initWithValidationMode:FBRCertificateValidationModePinnedCertificates
                           pinnedCertificates:certificates];
}

+ (instancetype)securityPolicyWithPinnedPublicKeysFromCertificates:(NSSet<NSData *> *)certificates {
  return [[self alloc] initWithValidationMode:FBRCertificateValidationModePinnedPublicKeys
                           pinnedCertificates:certificates];
}

- (instancetype)initWithValidationMode:(FBRCertificateValidationMode)validationMode
                    pinnedCertificates:(nullable NSSet<NSData *> *)certificates {
  LTParameterAssert(validationMode == FBRCertificateValidationModeStandard || certificates,
                    @"Security policy with non-standard validation mode requires pinned "
                    "certificates to be provided");

  if (self = [super init]) {
    _validationMode = validationMode;
    _pinnedCertificates = [certificates copy];
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(id)object {
  if (object == self) {
    return YES;
  } else if (![object isKindOfClass:[self class]]) {
    return NO;
  }

  FBRHTTPSessionSecurityPolicy *securityPolicy = object;
  return self.validationMode == securityPolicy.validationMode &&
      FBRCompare(self.pinnedCertificates, securityPolicy.pinnedCertificates);
}

- (NSUInteger)hash {
  return self.validationMode ^ self.pinnedCertificates.hash;
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

@end

NS_ASSUME_NONNULL_END
