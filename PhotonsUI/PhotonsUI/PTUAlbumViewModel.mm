// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTUAlbumViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTUAlbumViewModel

@synthesize dataSourceProvider = _dataSourceProvider;
@synthesize selectedAssets = _selectedAssets;
@synthesize scrollToAsset = _scrollToAsset;
@synthesize assetSelected = _assetSelected;
@synthesize defaultTitle = _defaultTitle;
@synthesize url = _url;

- (instancetype)initWithDataSourceProvider:(RACSignal *)dataSourceProvider
                            selectedAssets:(RACSignal *)selectedAssets
                             scrollToAsset:(RACSignal *)scrollToAsset
                              defaultTitle:(nullable NSString *)defaultTitle
                                       url:(nullable NSURL *)url {
  if (self = [super init]) {
    _dataSourceProvider = dataSourceProvider;
    _selectedAssets = selectedAssets;
    _scrollToAsset = scrollToAsset;
    _defaultTitle = defaultTitle;
    _url = url;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
