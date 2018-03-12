# Copyright (c) 2018 Lightricks. All rights reserved.

import common
import tensorflow as tf # pylint: disable=E0401

if __name__ == "__main__":
    test_name = "add"
    primary_input_name = common.tensor_file_name(test_name, "primary_input")
    secondary_input_name = common.tensor_file_name(test_name, "secondary_input")
    output_name = common.tensor_file_name(test_name, "output")

    primary_input_tensor = common.create_and_save_tensor(file_name=primary_input_name)
    secondary_input_tensor = common.create_and_save_tensor(file_name=secondary_input_name)
    output_tensor = tf.add(primary_input_tensor, secondary_input_tensor)

    common.evaluate_and_save(output_tensor, output_name)
