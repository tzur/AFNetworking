// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTexture+NSURL.h"

#import <LTEngine/LTTexture+Factory.h>
#import <LTKit/LTImageLoader.h>

#import "NSURL+DaVinci.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTTexture (NSURL)

#pragma mark -
#pragma mark Public API
#pragma mark -

+ (nullable LTTexture *)dvn_textureForURL:(NSURL *)url imageLoader:(LTImageLoader *)imageLoader {
  LTTexture * _Nullable texture = [LTTexture dvn_textureForDaVinciURL:url];
  if (texture) {
    return texture;
  }
  UIImage * _Nullable image = [imageLoader imageNamed:url.absoluteString];
  return image ? [LTTexture textureWithUIImage:image] : nil;
}

+ (nullable LTTexture *)dvn_textureForURL:(NSURL *)url {
  return [self dvn_textureForURL:url imageLoader:[LTImageLoader sharedInstance]];
}

#pragma mark -
#pragma mark Auxiliary Methods
#pragma mark -

+ (nullable instancetype)dvn_textureForDaVinciURL:(NSURL *)url {
  if ([url isEqual:[NSURL dvn_urlOfOneByOneWhiteSingleChannelByteTexture]]) {
    LTTexture *texture = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
    [texture clearColor:LTVector4::ones()];
    return texture;
  } else if ([url isEqual:[NSURL dvn_urlOfOneByOneWhiteNonPremultipliedRGBAByteTexture]]) {
    LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
    [texture clearColor:LTVector4::ones()];
    return texture;
  }

  return nil;
}

@end

NS_ASSUME_NONNULL_END
