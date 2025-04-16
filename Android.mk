LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_MODULE := GmsCore
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_CERTIFICATE := platform
LOCAL_PACKAGE_NAME := GmsCore

gmscore_root := $(LOCAL_PATH)
gmscore_dir := play-services-core
gmscore_gradle_apk := $(gmscore_root)/$(gmscore_dir)/build/outputs/apk/release/play-services-core-release-unsigned.apk
gmscore_out_apk := $(TARGET_COMMON_OUT_ROOT)/obj/APPS/$(LOCAL_MODULE)_intermediates/GmsCore.apk

LOCAL_PREBUILT_MODULE_FILE := $(gmscore_out_apk)
LOCAL_BUILT_MODULE_STEM := GmsCore.apk

include $(BUILD_PREBUILT)

# Ensure Gradle wrapper uses the local zipped Gradle distribution
$(gmscore_gradle_apk): PRIVATE_GMSCORE_ROOT := $(gmscore_root)
$(gmscore_gradle_apk):
	mkdir -p $(PRIVATE_GMSCORE_ROOT)/$(gmscore_dir)/build/outputs/apk/release
	mkdir -p $(PRIVATE_GMSCORE_ROOT)/.gradle

	# Set up JVM and Gradle memory
	echo "org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8" > $(PRIVATE_GMSCORE_ROOT)/gradle.properties

	# Set local SDK path (if needed, adjust this path to your AOSP SDK)
	echo "sdk.dir=$(TOP)/prebuilts/sdk" > $(PRIVATE_GMSCORE_ROOT)/local.properties

    # Write gradle-wrapper.properties with absolute path
    @echo "distributionUrl=file://$(abspath $(TOP))/prebuilts/gradle_cache/wrapper/gradle-8.1.1-bin.zip" > $(PRIVATE_GMSCORE_ROOT)/gradle/wrapper/gradle-wrapper.properties

	# Use local Gradle distribution and cached Maven repo only
	cd $(PRIVATE_GMSCORE_ROOT) && \
	env -u JAVA_TOOL_OPTIONS GRADLE_USER_HOME=$(PRIVATE_GMSCORE_ROOT)/.gradle \
	./gradlew --offline --no-daemon -p play-services-core assembleRelease

# Copy to AOSP output
$(gmscore_out_apk): $(gmscore_gradle_apk)
	@mkdir -p $(dir $@)
	cp -uv $< $@