// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "PNKProtobufHelpers.h"

#import "PNKProtobufMacros.h"

PNK_PROTOBUF_INCLUDE_BEGIN
#import <google/protobuf/repeated_field.h>
PNK_PROTOBUF_INCLUDE_END

SpecBegin(PNKProtobufHelpers)

it(@"should convert repeatedField", ^{
  google::protobuf::RepeatedField<float> repeatedField;
  repeatedField.Add(1.25);
  repeatedField.Add(2.5);
  repeatedField.Add(3.75);
  cv::Mat1f mat = pnk::createMat(repeatedField);

  expect(mat.rows).to.equal(1);
  expect(mat.cols).to.equal(repeatedField.size());
  expect(mat(0)).to.equal(repeatedField[0]);
  expect(mat(1)).to.equal(repeatedField[1]);
  expect(mat(2)).to.equal(repeatedField[2]);
});

it(@"should convert an empty repeatedField", ^{
  google::protobuf::RepeatedField<float> repeatedField;
  cv::Mat1f mat = pnk::createMat(repeatedField);
  expect(mat.empty()).to.beTruthy();
});

SpecEnd
