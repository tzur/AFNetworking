// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLTexture.h"

#import "LTGLException.h"
#import "LTGPUResourceExamples.h"
#import "LTTestUtils.h"
#import "LTTextureExamples.h"
#import "NSFileManager+LTKit.h"

// LTTexture spec is tested by the concrete class LTGLTexture.

// TODO: (yaron) refactor LTTexture to test the abstract functionality in a different spec. This
// is probably possible only by refactoring the LTTexture abstract class to the strategy pattern:
// http://stackoverflow.com/questions/243274/best-practice-with-unit-testing-abstract-classes

@interface LTFakeTextureContentsArchiverModel : NSObject <NSCoding> {
  cv::Mat _mat;
}

- (instancetype)initWithMat:(const cv::Mat &)mat;

@property (readonly, nonatomic) const cv::Mat &mat;
@property (strong, nonatomic) NSData *data;
@property (nonatomic) CGSize size;
@property (nonatomic) int type;

@end

@implementation LTFakeTextureContentsArchiverModel

- (instancetype)initWithMat:(const cv::Mat &)mat {
  if (self = [super init]) {
    _mat = mat;
    self.data = [NSData dataWithBytesNoCopy:mat.data length:mat.rows * mat.step[0]
                               freeWhenDone:NO];
    self.type = mat.type();
    self.size = CGSizeMake(mat.cols, mat.rows);
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  NSData *data = [aDecoder decodeObjectForKey:@"data"];
  CGSize size = [aDecoder decodeCGSizeForKey:@"size"];
  int type = [aDecoder decodeIntForKey:@"type"];

  cv::Mat mat(size.height, size.width, type);
  memcpy(mat.data, data.bytes, data.length);

  return [self initWithMat:mat];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  NSData *data = [NSData dataWithBytesNoCopy:_mat.data length:_mat.rows * _mat.step[0]
                                freeWhenDone:NO];
  [aCoder encodeObject:data forKey:@"data"];
  [aCoder encodeCGSize:CGSizeMake(_mat.cols, _mat.rows) forKey:@"size"];
  [aCoder encodeInt:_mat.type() forKey:@"type"];
}

@end

@interface LTFakeTextureContentsArchiver : NSObject <LTTextureContentsArchiver>
@end

@implementation LTFakeTextureContentsArchiver

- (id)initWithCoder:(NSCoder __unused *)aDecoder {
  return [self init];
}

- (void)encodeWithCoder:(NSCoder __unused *)aCoder {
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (NSData *)archiveTexture:(LTTexture *)texture error:(NSError *__autoreleasing __unused *)error {
  cv::Mat image = [texture image];
  LTFakeTextureContentsArchiverModel *model = [[LTFakeTextureContentsArchiverModel alloc]
                                               initWithMat:image];
  return [NSKeyedArchiver archivedDataWithRootObject:model];
}

- (BOOL)unarchiveData:(NSData *)data toTexture:(LTTexture *)texture
                error:(NSError *__autoreleasing __unused *)error {
  LTFakeTextureContentsArchiverModel *model = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  [texture load:model.mat];
  return YES;
}

@end

LTSpecBegin(LTTexture)

context(@"properties", ^{
  it(@"will not set wrap to repeat on NPOT texture", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 3)
                                                 precision:LTTexturePrecisionByte
                                                    format:LTTextureFormatRGBA allocateMemory:NO];
    texture.wrap = LTTextureWrapRepeat;

    expect(texture.wrap).toNot.equal(LTTextureWrapRepeat);
  });

  it(@"will set the warp to repeat on POT texture", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(2, 2)
                                                 precision:LTTexturePrecisionByte
                                                    format:LTTextureFormatRGBA allocateMemory:NO];
    texture.wrap = LTTextureWrapRepeat;

    expect(texture.wrap).to.equal(LTTextureWrapRepeat);
  });

  it(@"will set min and mag filters", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(2, 2)
                                                 precision:LTTexturePrecisionByte
                                                    format:LTTextureFormatRGBA allocateMemory:NO];

    texture.minFilterInterpolation = LTTextureInterpolationNearest;
    texture.magFilterInterpolation = LTTextureInterpolationNearest;

    expect(texture.minFilterInterpolation).to.equal(LTTextureInterpolationNearest);
    expect(texture.magFilterInterpolation).to.equal(LTTextureInterpolationNearest);
  });

  it(@"will set maximal mipmap level", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(2, 2)
                                                 precision:LTTexturePrecisionByte
                                                    format:LTTextureFormatRGBA allocateMemory:NO];
    texture.maxMipmapLevel = 1000;

    expect(texture.maxMipmapLevel).to.equal(1000);
  });
});

context(@"binding and execution", ^{
  __block LTTexture *texture;

  beforeEach(^{
    texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1) precision:LTTexturePrecisionByte
                                         format:LTTextureFormatRGBA allocateMemory:NO];
  });

  afterEach(^{
    texture = nil;
  });

  context(@"binding", ^{
    itShouldBehaveLike(kLTResourceExamples, ^{
      return @{kLTResourceExamplesSUTValue: [NSValue valueWithNonretainedObject:texture],
               kLTResourceExamplesOpenGLParameterName: @GL_TEXTURE_BINDING_2D};
    });
    
    it(@"should bind and unbind from the same texture unit", ^{
      glActiveTexture(GL_TEXTURE0);
      [texture bind];
      glActiveTexture(GL_TEXTURE1);
      [texture unbind];
      
      glActiveTexture(GL_TEXTURE0);
      GLint currentTexture;
      glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
      expect(currentTexture).to.equal(0);
    });
    
    it(@"should bind and execute block", ^{
      __block GLint currentTexture;
      __block BOOL didExecute = NO;
      glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
      expect(currentTexture).to.equal(0);
      [texture bindAndExecute:^{
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
        expect(currentTexture).toNot.equal(0);
        didExecute = YES;
      }];
      expect(didExecute).to.beTruthy();
    });

    it(@"should bind to two texture units at the same time", ^{
      glActiveTexture(GL_TEXTURE0);
      [texture bind];
      glActiveTexture(GL_TEXTURE1);
      [texture bind];

      GLint currentTexture;

      glActiveTexture(GL_TEXTURE0);
      glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
      expect(currentTexture).to.equal(texture.name);

      glActiveTexture(GL_TEXTURE1);
      glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
      expect(currentTexture).to.equal(texture.name);
    });
  });
  
  context(@"execution", ^{
    it(@"should execute a block", ^{
      __block BOOL didExecute = NO;
      [texture executeAndPreserveParameters:^{
        didExecute = YES;
      }];
      expect(didExecute).to.beTruthy();
    });
    
    it(@"should raise exception when trying to execute a nil block", ^{
      expect(^{
        [texture executeAndPreserveParameters:nil];
      }).to.raise(NSInvalidArgumentException);
    });

    itShouldBehaveLike(kLTTextureDefaultValuesExamples, ^{
      [texture executeAndPreserveParameters:^{
        texture.minFilterInterpolation = LTTextureInterpolationNearest;
        texture.magFilterInterpolation = LTTextureInterpolationNearest;
        texture.wrap = LTTextureWrapRepeat;
      }];
      return @{kLTTextureDefaultValuesExamplesTexture:
                 [NSValue valueWithNonretainedObject:texture]};
    });
  });
});

context(@"coding and decoding", ^{
  it(@"should code and decode correctly", ^{
    LTGLTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(2, 5)
                                                   precision:LTTexturePrecisionByte
                                                      format:LTTextureFormatRGBA
                                              allocateMemory:YES];
    texture.contentsArchiver = [[LTFakeTextureContentsArchiver alloc] init];

    texture.minFilterInterpolation = LTTextureInterpolationNearest;
    texture.usingAlphaChannel = YES;
    texture.usingHighPrecisionByte = YES;

    cv::Mat1b image(texture.size.height, texture.size.width);
    for (int y = 0; y < image.rows; ++y) {
      for (int x = 0; x < image.cols; ++x) {
        image(y, x) = x + y;
      }
    }

    NSData *encoded = [NSKeyedArchiver archivedDataWithRootObject:texture];
    LTTexture *decoded = [NSKeyedUnarchiver unarchiveObjectWithData:encoded];

    expect(decoded.size).to.equal(texture.size);
    expect(decoded.precision).to.equal(texture.precision);
    expect(decoded.channels).to.equal(texture.channels);
    expect(decoded.format).to.equal(texture.format);
    expect(decoded.usingAlphaChannel).to.equal(texture.usingAlphaChannel);
    expect(decoded.usingHighPrecisionByte).to.equal(texture.usingHighPrecisionByte);
    expect(decoded.minFilterInterpolation).to.equal(texture.minFilterInterpolation);
    expect(decoded.magFilterInterpolation).to.equal(texture.magFilterInterpolation);
    expect(decoded.wrap).to.equal(texture.wrap);
    expect(decoded.maxMipmapLevel).to.equal(texture.maxMipmapLevel);
    expect($([decoded image])).to.equalMat($([texture image]));
  });
});

LTSpecEnd
