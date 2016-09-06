// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRCertificatePinning.h"

SpecBegin(FBRCertificatePinning)

it(@"should decrypt an encrypted certificate data", ^{
  NSString *key = @"foo-bar-baz";
  NSMutableData *buffer = [[NSMutableData alloc] initWithLength:1024];

  for (NSUInteger i = 0; i < 1024; ++i) {
    ((char *)buffer.bytes)[i] = i % 256;
  }

  NSData *encryptedBuffer = FBREncryptCertificate(buffer, key);
  NSData *decryptedBuffer = FBRDecryptCertificate(encryptedBuffer, key);

  expect(encryptedBuffer).toNot.beNil();
  expect(encryptedBuffer).toNot.equal(buffer);
  expect(decryptedBuffer).to.equal(buffer);
});

SpecEnd
