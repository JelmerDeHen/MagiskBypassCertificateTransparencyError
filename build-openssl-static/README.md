If you don't want to use the precompiled binaries you can use wrapper.sh to compile from src. It will compile and extract the openssl binaries to the out directory.

```sh
bash wrapper.sh build
# Overwrite the original openssl libraries with the new ones
mv out/* ../bin
```

Building requires a locally installed NDK locatable via `$ANDROID_HOME` or `$ANDROID_SDK_HOME`. The produced bins will be statically linked.
