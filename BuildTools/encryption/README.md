Build System Encryption Scripts
===============================

Here is an overview of the encryption mechanism contained in this directory, and how to use it as an API.

AESEncryptor.py
---------------

Encrypts files using PKCS#7/AES256. It can be used as a module or as a command line tool.

XorEncryptor.py
---------------

Encrypts files using cyclic xor encryption. It can be used as a module or as a command line tool.

EncryptShader.py
-----------------

Script which given an input directory, output directory, project name and an encryption key, generates an objective-c class in the files named `LTShaderStorage+<Shader Name>.h` and `LTShaderStorage+<Shader Name>.m`. The class includes an encrypted version of the shaders (all files with .vsh and .fsh extensions), and an interface for accessing the plaintext source of them.

Two methods are available to retrieve a shader source:

- Call the class method `[LTShaderStorage <Shader Name>]`.
- Call the class method `[LTShaderStorage shaderSourceWithName:<Shader Name>]`.

Where `<Shader Name>` is the shader file name including extension, without the dot and mixed cased.

Example:
The shader file `MyNiceShader.vsh` will be named as `myNiceShaderVsh`.

The first option is preferable, because it allows compile-time verification for the method call.
Using the Shader Storage
------------------------

1. Add an `#import LTShaderStorage+<Shader Name>.h` directive at the beginning of the file.
2. Retrieve the desired shader source NSString using the methods discussed in `EncryptShader.py`.
3. Instead of initializing the shader from a path (and an optional bundle), use initializers that accept source vertex and fragment shaders.
