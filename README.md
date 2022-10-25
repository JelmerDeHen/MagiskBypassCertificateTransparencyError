# Technical info
This module does the following:
- The module bundles statically compiled openssl binaries for x86/x64/arm/arm64 to generate SPKI fingerprints for the user installed CA certificates on the device
- Create flag files picked up by Chrome containing `--ignore-certificate-errors-spki-list` flag configured to the SPKI fingerprints for the user installed CAs
- Configure global settings debug value to `com.android.chrome`

This allows us to bypass the Certificate Transparency (CT) error `NET::ERR_CERTIFICATE_TRANSPARENCY_REQUIRED` for self-signed certificates.

The flags used when Android starts Chrome can be manipulated using the following files.

```
/data/local/chrome-command-line
/data/local/android-webview-command-line
/data/local/webview-command-line
/data/local/content-shell-command-line
/data/local/tmp/chrome-command-line
/data/local/tmp/android-webview-command-line
/data/local/tmp/webview-command-line
/data/local/tmp/content-shell-command-line
```

Chrome will use these files when the `chrome://flags` option `Enable command line on non-rooted devices` is `Enabled`.

This works on `eng` and `userdebug` builds out of the box. On `user` builds you need to configure the global system-level device preference `debug_app` to `com.android.chrome` to make it load the flag files. If you are experiencing `NET::ERR_CERTIFICATE_TRANSPARENCY_REQUIRED` on an app other than `com.android.chrome`, configuring the `debug_app` to that app is the solution (`adb shell su -c settings put global debug_app <appname>`).

# Installation
## Option 1: Install Magisk module
1. Visit `chrome://flags` and set `Enable command line on non-rooted devices` to `Enabled`
2. Install user CA cert ([instructions](https://portswigger.net/support/installing-burp-suites-ca-certificate-in-an-android-device))
3. Install [Magisk](https://topjohnwu.github.io/Magisk/install.html)
4. Download Magisk [module](https://github.com/JelmerDeHen/MagiskBypassCertificateTransparencyError/releases/download/v0.0.1/MagiskBypassCertificateTransparencyError.zip)
5. Install Magisk module in Magisk app

Visit [chrome://version](chrome://version) and verify that the `--ignore-certificate-errors-spki-list` flag is picked up by Chrome.

## Option 2: Create and install Magisk module

Use the following steps to compile the Magisk module manually.

```sh
git clone https://github.com/JelmerDeHen/MagiskBypassCertificateTransparencyError
cd MagiskBypassCertificateTransparencyError

# Compile statically compiled openssl binaries
bash build-openssl-static/wrapper.sh build

# Overwrite the precompiled binaries with your compiled binaries now located in `build-openssl-static/out`
mv -v build-openssl-static/out/* bin

# Create Magisk module
zip -r MagiskBypassCertificateTransparencyError.zip bin META-INF module.prop openssl-arm openssl-arm64 openssl-x64 openssl-x86 post-fs-data.sh update_info.json

# Upload module to device
adb push MagiskBypassCertificateTransparencyError.zip /sdcard/Download
```

Now install the module in the Magisk app.

## Option 3: Without Magisk

When you don't use Magisk but have root you can follow these steps to manually change the Chrome flags.

### Step 1: Generate SPKI fingerprints

Use the CA certificate in DER format you are using to issue self-signed certificates. The `der2spki.sh` script can be used to generate SPKI fingerprints.

```sh
# Generate SPKI fingerprint
bash der2spki.sh cacert.der
```

This script can also directly connect to your device over adb and generate SPKI fingerprints for the user installed certificates located at `/data/misc/user/0/cacerts-added/` on the device.

To do this run:

```sh
bash der2spki.sh adb
```

### Step 2: Create command line flag files

Android applications don't have command line arguments. Instead they're simulated by reading a file at a specific location early during startup. Applications each defined their own files. The Chrome application (`com.android.chrome`) provides functionality to change the parameters via a series of files under `/data/local/` and `/data/local/tmp`.


Create the files used by Chrome:

```sh
# Replace with your generated SPKI in step 1
FLAGS='chrome --ignore-certificate-errors-spki-list=<SPKI>'
# Create the flag files
echo "${FLAGS}" | adb shell su -c tee /data/local/chrome-command-line /data/local/android-webview-command-line /data/local/webview-command-line /data/local/content-shell-command-line /data/local/tmp/chrome-command-line /data/local/tmp/android-webview-command-line /data/local/tmp/webview-command-line /data/local/tmp/content-shell-command-line
# Set permissions on flag files
echo 'chmod 555 /data/local/*-command-line /data/local/tmp/*-command-line' | adb shell su
```

If you are on a `eng` or `userdebug` build continue with step 4.

### Step 3: Configure Chrome to use command line flags

Chrome picks up the command line parameters when:
- Current build is `eng` or `userdebug`
- Adb is enabled and this is the debug app

Check the Android build variant.

```sh
adb shell getprop ro.build.type
```

When the `ro.build.type` is `user` then enable adb and configure the debug app to `com.android.chrome`, on `eng` and `userdebug` builds this can be skipped.

```sh
adb shell settings put global adb_enabled 1
# This requires root
adb shell su -c settings put global debug_app com.android.chrome
```

### Step 4: Enable command line on non-rooted devices

Visit `chrome://flags` and set `Enable command line on non-rooted devices` to `Enabled`

### Step 5: Restart Chrome

Restart Chrome and visit `chrome://version` to check debug flags.

```sh
adb shell su -c killall com.android.chrome
adb shell am start -n com.android.chrome/com.google.android.apps.chrome.Main
```

# Related Chrome sources

Chrome checks if it should use the flag files in `shouldUseDebugCommandLine()`.

[https://chromium.googlesource.com/chromium/src/+/HEAD/base/android/java/src/org/chromium/base/CommandLineInitUtil.java#53](https://chromium.googlesource.com/chromium/src/+/HEAD/base/android/java/src/org/chromium/base/CommandLineInitUtil.java#53)
```java
    public static void initCommandLine(String fileName) {
        initCommandLine(fileName, null);
    }

    public static void initCommandLine(
            String fileName, @Nullable Supplier<Boolean> shouldUseDebugFlags) {
        assert !CommandLine.isInitialized();
        File commandLineFile = new File(COMMAND_LINE_FILE_PATH_DEBUG_APP, fileName);
        // shouldUseDebugCommandLine() uses IPC, so don't bother calling it if no flags file exists.
        boolean debugFlagsExist = commandLineFile.exists();
        if (!debugFlagsExist || !shouldUseDebugCommandLine(shouldUseDebugFlags)) {
            commandLineFile = new File(COMMAND_LINE_FILE_PATH, fileName);
        }
        CommandLine.initFromFile(commandLineFile.getPath());
    }

    private static boolean shouldUseDebugCommandLine(
            @Nullable Supplier<Boolean> shouldUseDebugFlags) {
        if (shouldUseDebugFlags != null && shouldUseDebugFlags.get()) return true;
        Context context = ContextUtils.getApplicationContext();
        // Check isDebugAndroid() last to get full code coverage when using userdebug devices.
        return context.getPackageName().equals(getDebugApp(context)) || BuildInfo.isDebugAndroid();
    }

    private static String getDebugApp(Context context) {
        boolean adbEnabled = Settings.Global.getInt(context.getContentResolver(),
                Settings.Global.ADB_ENABLED, 0) == 1;
        if (adbEnabled) {
            return Settings.Global.getString(context.getContentResolver(),
                    Settings.Global.DEBUG_APP);
        }
        return null;
    }
```

[https://chromium.googlesource.com/chromium/src/+/HEAD/base/android/java/src/org/chromium/base/BuildInfo.java#249](https://chromium.googlesource.com/chromium/src/+/HEAD/base/android/java/src/org/chromium/base/BuildInfo.java#249)
```java
    public static boolean isDebugAndroid() {
        return "eng".equals(Build.TYPE) || "userdebug".equals(Build.TYPE);
    }
```

[https://source.chromium.org/chromium/chromium/src/+/main:chrome/android/java/src/org/chromium/chrome/browser/base/SplitCompatApplication.java](https://source.chromium.org/chromium/chromium/src/+/main:chrome/android/java/src/org/chromium/chrome/browser/base/SplitCompatApplication.java;l=322)
```java
    private static Boolean shouldUseDebugFlags() {
        return ChromeFeatureList.sCommandLineOnNonRooted.isEnabled();
    }
```

# Changelog

## v0.1
* Initial release

# Links
- https://chromium.googlesource.com/chromium/src/+/master/net/docs/certificate-transparency.md
- https://httptoolkit.tech/blog/chrome-android-certificate-transparency
- https://certificate.transparency.dev/
