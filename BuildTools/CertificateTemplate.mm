// Copyright (c) @YEAR@ Lightricks. All rights reserved.
// Created by @SCRIPT_NAME@.

#import <Fiber/FBRCertificatePinning.h>

@CERTIFICATE_BUFFER@

NSData *@PROJECT_PREFIX@@CERTIFICATE_NAME@CertificateData() {
  NSData *buffer = [[NSData alloc] initWithBytesNoCopy:(void *)k@CERTIFICATE_NAME@Buffer
                                                length:sizeof(k@CERTIFICATE_NAME@Buffer)
                                          freeWhenDone:NO];
  return FBRDecryptCertificate(buffer, @@ENCRYPTION_KEY@);
}
