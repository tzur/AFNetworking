// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTProgramFactory.h"

#import "LTProgram.h"

#pragma mark -
#pragma mark LTBasicProgramFactory
#pragma mark -

@implementation LTBasicProgramFactory

- (LTProgram *)programWithVertexSource:(NSString *)vertexSource
                        fragmentSource:(NSString *)fragmentSource {
  return [[LTProgram alloc] initWithVertexSource:vertexSource fragmentSource:fragmentSource];
}

@end

#pragma mark -
#pragma mark LTMaskableProgramFactory
#pragma mark -

@implementation LTMaskableProgramFactory

NSString * const kLTMaskableProgramInputUniformName = @"_input";
NSString * const kLTMaskableProgramMaskUniformName = @"_mask";
NSString * const kLTMaskableProgramDefaultSamplingVaryingName = @"vTexcoord";

- (instancetype)init {
  return [self initWithInputColorVariableName:nil];
}

- (instancetype)initWithInputColorVariableName:(NSString *)inputColor {
  if (self = [super init]) {
    _inputColorVariableName = inputColor;

    self.samplingVaryingName = kLTMaskableProgramDefaultSamplingVaryingName;
  }
  return self;
}

- (LTProgram *)programWithVertexSource:(NSString *)vertexSource
                        fragmentSource:(NSString *)fragmentSource {
  NSString *maskedFragmentSource = [self addMaskingToFragmentSource:fragmentSource];
  return [[LTProgram alloc] initWithVertexSource:vertexSource fragmentSource:maskedFragmentSource];
}

- (NSString *)addMaskingToFragmentSource:(NSString *)fragmentSource {
  NSMutableString *maskedFragment = [fragmentSource mutableCopy];

  if (!self.inputColorVariableName) {
    [self addSamplerForUniformName:kLTMaskableProgramInputUniformName
                    fragmentSource:maskedFragment];
  }
  [self addSamplerForUniformName:kLTMaskableProgramMaskUniformName
                  fragmentSource:maskedFragment];
  [self addMixingToFragmentSource:maskedFragment];

  return maskedFragment;
}

- (void)addSamplerForUniformName:(NSString *)name fragmentSource:(NSMutableString *)fragmentSource {
  NSUInteger insertLocation = [self uniformInsertLocationForFragmentSource:fragmentSource];
  NSString *sampler = [self samplerForUniformName:name];
  [fragmentSource insertString:sampler atIndex:insertLocation];
}

- (NSUInteger)uniformInsertLocationForFragmentSource:(NSString *)fragmentSource {
  NSUInteger insertLocation = 0;
  for (NSString *line in [fragmentSource componentsSeparatedByString:@"\n"]) {
    if ([line rangeOfString:@"#define"].location == 0 ||
        [line rangeOfString:@"#extension"].location == 0) {
      // Adding 1 to compensate on the '\n' that was omitted.
      insertLocation += line.length + 1;
    }
  }

  return insertLocation;
}

- (NSString *)samplerForUniformName:(NSString *)name {
  return [NSString stringWithFormat:@"uniform sampler2D %@;\n", name];
}

- (void)addMixingToFragmentSource:(NSMutableString *)fragmentSource {
  NSRange lastCurlyBrace = [fragmentSource rangeOfString:@"}" options:NSBackwardsSearch];
  LTAssert(lastCurlyBrace.location != NSNotFound, @"'}' not found in shader");

  [fragmentSource insertString:[self mixingCode] atIndex:lastCurlyBrace.location];
}

- (NSString *)mixingCode {
  NSString *maskSampling =
      [NSString stringWithFormat:@"mediump float %@Color = texture2D(%@, %@).r;\n",
       kLTMaskableProgramMaskUniformName, kLTMaskableProgramMaskUniformName,
       self.samplingVaryingName];

  NSString *epilogue = self.inputColorVariableName ? [self mixingCodeForSampledInput] :
      [self mixingCodeForNonSampledInput];

  return [@[maskSampling, epilogue] componentsJoinedByString:@"\n"];
}

- (NSString *)mixingCodeForSampledInput {
  return [NSString stringWithFormat:@"gl_FragColor = mix(%@, gl_FragColor, %@Color);\n",
          self.inputColorVariableName, kLTMaskableProgramMaskUniformName];
}

- (NSString *)mixingCodeForNonSampledInput {
  NSString *inputSampling = [NSString stringWithFormat:@"lowp vec4 %@Color = texture2D(%@, %@);\n",
                             kLTMaskableProgramInputUniformName,
                             kLTMaskableProgramInputUniformName,
                             self.samplingVaryingName];

  NSString *mixing = [NSString
                      stringWithFormat:@"gl_FragColor = mix(%@Color, gl_FragColor, %@Color);\n",
                      kLTMaskableProgramInputUniformName, kLTMaskableProgramMaskUniformName];

  return [@[inputSampling, mixing] componentsJoinedByString:@"\n"];
}

@end
