

build:
				rm MagiskBypassCertificateTransparencyError.zip
				zip -r MagiskBypassCertificateTransparencyError.zip ./*

install:
				adb push MagiskBypassCertificateTransparencyError.zip /storage/emulated/0/Download
