# Copyright (c) 2018 Lightricks. All rights reserved.

import common
import tensorflow as tf # pylint: disable=E0401

if __name__ == "__main__":
    test_name = "activation_relu"
    input_name = common.tensor_file_name(test_name, "input", common.default_tensor_shape)
    output_name = common.tensor_file_name(test_name, "output", common.default_tensor_shape)

    input_tensor = common.create_and_save_tensor(file_name=input_name)
    output_tensor = tf.nn.relu(features=input_tensor)
    common.evaluate_and_save(output_tensor, output_name)
