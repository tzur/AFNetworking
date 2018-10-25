# Copyright (c) 2018 Lightricks. All rights reserved.

import os

import common
import numpy as np # pylint: disable=E0401
import tensorflow as tf # pylint: disable=E0401

if __name__ == "__main__":
    test_name = "batch_normalization"
    epsilon = 1e-5
    input_name = common.tensor_file_name(test_name, "input", common.default_tensor_shape)
    output_name = common.tensor_file_name(test_name, "output", common.default_tensor_shape)

    input_tensor = common.create_and_save_tensor(file_name=input_name, create_as=np.float32)
    output_tensor = tf.layers.batch_normalization(
        inputs=input_tensor,
        beta_initializer=tf.initializers.random_normal(),
        gamma_initializer=tf.initializers.random_normal(),
        moving_mean_initializer=tf.initializers.random_normal(),
        moving_variance_initializer=tf.initializers.random_normal(),
        epsilon=epsilon,
        training=False
    )
    common.evaluate_and_save(output_tensor, output_name)

    beta_name = "{}_{}_{}.weights".format(test_name, "beta", common.default_tensor_shape[-1])
    os.rename("batch_normalization_beta_0", beta_name)

    gamma_name = "{}_{}_{}.weights".format(test_name, "gamma", common.default_tensor_shape[-1])
    os.rename("batch_normalization_gamma_0", gamma_name)

    mean_name = "{}_{}_{}.weights".format(test_name, "mean", common.default_tensor_shape[-1])
    os.rename("batch_normalization_moving_mean_0", mean_name)

    var_name = "{}_{}_{}.weights".format(test_name, "variance", common.default_tensor_shape[-1])
    os.rename("batch_normalization_moving_variance_0", var_name)

    epsilon_name = "{}_{}_{}.weights".format(test_name, "epsilon", 1)
    common.save_array(np.array(epsilon), epsilon_name)
