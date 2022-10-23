ZIPOUT=MagiskBypassCertificateTransparencyError.zip

build:
				zip -r $(ZIPOUT) ./*

clean:
				rm -f $(ZIPOUT)

install:
				adb push $(ZIPOUT) /storage/emulated/0/Download

