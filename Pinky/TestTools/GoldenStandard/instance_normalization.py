# Copyright (c) 2018 Lightricks. All rights reserved.

import common
import numpy as np # pylint: disable=E0401
import tensorflow as tf # pylint: disable=E0401


def instance_normalization(inputs, beta, gamma, activation_fn):
    """ Instance normalization
    Shifts and scales the output of a spatial normalization with an offset and scale parameters.

    """
    image_spatial_dimensions = [1, 2]
    # calculate the mean and variance with respect to the spatial dimensions
    mean, std = tf.nn.moments(inputs, image_spatial_dimensions, keep_dims=True)
    # compute instance normalization
    variance_epsilon = 1E-5
    outputs = tf.nn.batch_normalization(inputs,
                                        mean,
                                        std,
                                        offset=beta,
                                        scale=gamma,
                                        variance_epsilon=variance_epsilon)

    if activation_fn:
        outputs = activation_fn(outputs)
    return outputs


def create_instance_normalization_test(test_name,
                                       tensor_shape=common.default_tensor_shape,
                                       activation_fn=None):
    input_name = common.tensor_file_name(test_name, "input", tensor_shape)
    beta_name = "{}_{}_{}.weights".format(test_name, "beta", tensor_shape[-1])
    gamma_name = "{}_{}_{}.weights".format(test_name, "gamma", tensor_shape[-1])
    output_name = common.tensor_file_name(test_name, "output", tensor_shape)

    input_tensor = common.create_and_save_tensor(input_name, input_shape=tensor_shape,
                                                 create_as=np.float32)
    beta = common.create_and_save_tensor(beta_name,
                                         input_shape=tensor_shape[-1:],
                                         create_as=np.float32,
                                         save_as=np.float32)
    gamma = common.create_and_save_tensor(gamma_name,
                                         input_shape=tensor_shape[-1:],
                                         create_as=np.float32,
                                         save_as=np.float32)

    output_tensor = instance_normalization(inputs=input_tensor,
                                           beta=beta,
                                           gamma=gamma,
                                           activation_fn=activation_fn)

    common.evaluate_and_save(output_tensor, output_name)


if __name__ == "__main__":
    create_instance_normalization_test("instance_normalization_basic")
    create_instance_normalization_test("instance_normalization_single_texture",
                                       tensor_shape=(common.default_tensor_shape[0],
                                                     common.default_tensor_shape[1],
                                                     common.default_tensor_shape[2],
                                                     3))
    create_instance_normalization_test("instance_normalization_relu", activation_fn=tf.nn.relu)
