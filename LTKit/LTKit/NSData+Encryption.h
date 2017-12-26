// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@interface NSData (Encryption)

/// Decrypts the AES128 encrypted receiver using the given \c key. The data is assumed to begin with
/// the IV and then to continue with the actual encrypted data. If the decryption succeeded, the
/// decrypted data is returned, otherwise \c nil is returned and \c error is populated with
/// \c LTErrorCodeDecryptionFailed.
///
/// @note the decryptor assumes that the encryptor used a PKCS7 padding before encryption and that
/// the plaintext is safe to use with that padding.
///
/// @note a mutable container is returned for performance reasons. The returned object is not
/// retained nor modified by the receiver after this method returns.
- (nullable instancetype)lt_decryptWithKey:(NSData *)key error:(NSError **)error;

/// Encrypts the receiver with AES128 using the given \c key and \c iv. If the encryption succeeded,
/// the encrypted data is returned, otherwise \c nil is returned and \c error is populated with
/// \c LTErrorCodeEncryptionFailed. The encrypted buffer is prepended with \c iv so that the
/// resulting data can be used with \c lt_decryptWithKey to decrypt the data.
///
/// @note the receiver is padded using PCKS7 before encryption.
///
/// @note a mutable container is returned for performance reasons. The returned object is not
/// retained nor modified by the receiver after this method returns.
///
/// NSInvalidArgumentException is raised if \c iv size is not \c kCCBlockSizeAES128.
- (nullable instancetype)lt_encryptWithKey:(NSData *)key iv:(NSData *)iv error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
