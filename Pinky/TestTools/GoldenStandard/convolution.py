# Copyright (c) 2018 Lightricks. All rights reserved.

import os

import common
import tensorflow as tf # pylint: disable=E0401

def create_convolution_test(test_name, kernel_size=(3, 3), strides=(1, 1), dilation_rate=(1, 1)):
    input_name = common.tensor_file_name(test_name, "input", common.default_tensor_shape)

    output_channels = 16
    output_tensor_shape = (common.default_tensor_shape[0],
                           (common.default_tensor_shape[1] + strides[0] - 1) // strides[0],
                           (common.default_tensor_shape[2] + strides[1] - 1) // strides[1],
                           output_channels)
    output_name = common.tensor_file_name(test_name, "output", output_tensor_shape)

    input_tensor = common.create_and_save_tensor(file_name=input_name)

    output_tensor = tf.layers.conv2d(inputs=input_tensor,
                                     filters=output_channels,
                                     kernel_size=kernel_size,
                                     strides=strides,
                                     dilation_rate=dilation_rate,
                                     kernel_initializer=tf.random_normal_initializer(),
                                     bias_initializer=tf.zeros_initializer(),
                                     name=test_name,
                                     padding="same")
    common.evaluate_and_save(output_tensor, output_name)

    bias_name = "{}_bias_{}.weights".format(test_name, output_channels)
    os.rename("{}_bias_0".format(test_name), bias_name)

    kernel_name = "{}_kernel_{}x{}x{}x{}.weights".format(test_name, output_channels, kernel_size[0],
                                                         kernel_size[1],
                                                         common.default_tensor_shape[3])
    os.rename("{}_kernel_0".format(test_name), kernel_name)
    tf.reset_default_graph()

if __name__ == "__main__":
    create_convolution_test("conv_basic")
    create_convolution_test("conv_stride", strides=(2, 2))
    create_convolution_test("conv_dilation", dilation_rate=(3, 3))
