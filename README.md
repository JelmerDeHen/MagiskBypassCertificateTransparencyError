# Magisk Bypass Certificate Transparency
This module bypasses the Certificate Transparency (CT) certificate error for Android `user` build type roms in Chrome (com.android.chrome) by configuring it to use the `--ignore-certificate-errors-spki-list` flag. Chrome does not verify the correctness of the subjectPublicKeyInformation (SPKI) parameter so no `openssl` is needed. 

Chrome version 99 introduced Certificate Transparency (CT) resulting in `NET::ERR_CERTIFICATE_TRANSPARENCY_REQUIRED` certificate errors when mitming using custom CA from system bundle. This is problematic when using an intercepting proxy issuing self-signed certificates.

Certificate Transparency can be disabled in Chrome using the following chrome flag.

```sh
chrome --ignore-certificate-errors-spki-list=1
```

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

Chrome will use this method when the `chrome://flags` option `Enable command line on non-rooted devices` is `Enabled`. This works on `eng` and `userdebug` buildtype images, but not on `user` buildtype images. It was found that by configuring the global system-level device preference `debug_app` to `com.android.chrome` Chrome will happily use the flags and as-such and it is possible to change the Chrome parameters.

# Installation
1. Visit `chrome://flags` and set `Enable command line on non-rooted devices` to `Enabled`
1. Install [Magisk](https://github.com/topjohnwu/Magisk/releases)
2. Zip files `zip -r MagiskBypassCertificateTransparencyError.zip ./*`
3. Install in Magisk
4. Restart your device.
5. Visit `chrome://version` and verify `--ignore-certificate-errors-spki-list` flag is present

# Manually

If you don't use Magisk but have root you could run the following manually:

```
settings put global adb_enabled 1
settings put global debug_app com.android.chrome

printf 'chrome --ignore-certificate-errors-spki-list=1' > /data/local/tmp/chrome-command-line

while read -r; do
  cp /data/local/tmp/chrome-command-line "${REPLY}"
  chmod 555 "${REPLY}"
done < <<EOF
/data/local/chrome-command-line
/data/local/android-webview-command-line
/data/local/webview-command-line
/data/local/content-shell-command-line
/data/local/tmp/chrome-command-line
/data/local/tmp/android-webview-command-line
/data/local/tmp/webview-command-line
/data/local/tmp/content-shell-command-line
EOF
```

Then `killall com.android.chrome` and it should work.

### Changelog

#### v0.2
* Discovered that the value of Chrome flag `--ignore-certificate-errors-spki-list` does not matter and deleted SPKI fingerprint creation logic

#### v0.1
* Initial release

# Technical info

Chrome performs an extra check in the function `shouldUseDebugCommandLine()`.

https://source.chromium.org/chromium/chromium/src/+/main:base/android/java/src/org/chromium/base/CommandLineInitUtil.java
```java
    /**
     * Use an alternative path if:
     * - The current build is "eng" or "userdebug", OR
     * - adb is enabled and this is the debug app, OR
     * - Force enabled by the embedder.
     * @param shouldUseDebugFlags If non-null, returns whether debug flags are allowed to be used.
     */
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

https://source.chromium.org/chromium/chromium/src/+/main:chrome/android/java/src/org/chromium/chrome/browser/base/SplitCompatApplication.java;l=322
```java
    private static Boolean shouldUseDebugFlags() {
        return ChromeFeatureList.sCommandLineOnNonRooted.isEnabled();
    }
```

https://chromium.googlesource.com/chromium/src/+/HEAD/base/android/java/src/org/chromium/base/BuildInfo.java#249
```java
    /**
     * Check if this is a debuggable build of Android. Use this to enable developer-only features.
     * This is a rough approximation of the hidden API {@code Build.IS_DEBUGGABLE}.
     */
    public static boolean isDebugAndroid() {
        return "eng".equals(Build.TYPE) || "userdebug".equals(Build.TYPE);
    }
```

The first check `ChromeFeatureList.sCommandLineOnNonRooted.isEnabled()` verifies if the flag was configured in `chrome://flags`.

To make the function `shouldUseDebugCommandLine()` return true one of the following prerequisites must be true:
- `ro.build.type` is `eng` or `userdebug`
- System property `adb_enabled=1` and `debug_app=com.android.chrome`: Can be changed as root `settings put global debug_app com.android.chrome`


# Links
- https://chromium.googlesource.com/chromium/src/+/master/net/docs/certificate-transparency.md
- https://httptoolkit.tech/blog/chrome-android-certificate-transparency

