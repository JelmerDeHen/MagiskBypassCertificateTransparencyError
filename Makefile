zip=MagiskBypassCertificateTransparencyError.zip

build:
				rm $(zip)
				zip -r $(zip) META-INF module.prop openssl-arm openssl-arm64 openssl-x64 openssl-x86 post-fs-data.sh

install:
				adb push $(zip) /storage/emulated/0/Download
