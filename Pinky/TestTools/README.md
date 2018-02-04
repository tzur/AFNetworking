# TestTools - tools for creating Pinky test data

## Contents

1. GoldenStandard - collection of Python scripts for generating Tensorflow Golden Standard test data
for PinkyDeviceTests. Each script generates an input tensor, runs TensorFlow kernels on it and
stores input and output tensors alongside with kernel parameters. This way Pinky kernels can be 
validated against their TensorFlow counterparts.
