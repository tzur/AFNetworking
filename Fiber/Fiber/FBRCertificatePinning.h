// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Encrypts a \c buffer containing certificate data using the given \c key. The encrypted
/// certificate can later be decrypted using \c FBRDecryptCertificate.
NSData *FBREncryptCertificate(NSData *buffer, NSString *key);

/// Decrypts a \c buffer containing certificate data that was encrypted by the certificate
/// encryption build scripts or by \c FBREncryptCertificateForPinning with the given \c key.
NSData *FBRDecryptCertificate(NSData *buffer, NSString *key);

NS_ASSUME_NONNULL_END
