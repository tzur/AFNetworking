# Copyright (c) 2018 Lightricks. All rights reserved.

import common
import tensorflow as tf # pylint: disable=E0401

if __name__ == "__main__":
    test_name = "softmax"

    input_name = common.tensor_file_name(test_name, "input")
    output_name = common.tensor_file_name(test_name, "output")

    input_tensor = common.create_and_save_tensor(file_name=input_name)
    output_tensor = tf.nn.softmax(input_tensor)

    common.evaluate_and_save(output_tensor, output_name)
