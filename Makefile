zip=MagiskBypassCertificateTransparencyError.zip

build:
				zip -r $(zip) bin META-INF module.prop openssl-arm openssl-arm64 openssl-x64 openssl-x86 post-fs-data.sh update_info.json

install:
				adb push $(zip) /sdcard/Download
