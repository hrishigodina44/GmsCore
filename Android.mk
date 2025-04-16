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

# Step 1: Build the APK via Gradle
$(gmscore_gradle_apk): PRIVATE_GMSCORE_ROOT := $(gmscore_root)
$(gmscore_gradle_apk):
	mkdir -p $(PRIVATE_GMSCORE_ROOT)/$(gmscore_dir)/build/outputs/apk/release
	mkdir -p $(PRIVATE_GMSCORE_ROOT)/.gradle

	# Fix the gradlew script JVM opts
	sed -i'' -e 's/DEFAULT_JVM_OPTS=.*/DEFAULT_JVM_OPTS="-Dfile.encoding=UTF-8"/' $(PRIVATE_GMSCORE_ROOT)/gradlew || \
	sed -i -e 's/DEFAULT_JVM_OPTS=.*/DEFAULT_JVM_OPTS="-Dfile.encoding=UTF-8"/' $(PRIVATE_GMSCORE_ROOT)/gradlew

	# Write gradle.properties to force memory settings
	echo "org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8" > $(PRIVATE_GMSCORE_ROOT)/gradle.properties

	# Write local.properties with sdk path
	echo "sdk.dir=$(ANDROID_HOME)" > $(PRIVATE_GMSCORE_ROOT)/local.properties

	# Run gradle build
	cd $(PRIVATE_GMSCORE_ROOT) && \
	env -u JAVA_TOOL_OPTIONS GRADLE_USER_HOME=$(PRIVATE_GMSCORE_ROOT)/.gradle ./gradlew --no-daemon -p play-services-core assembleRelease

# Step 2: Copy it into AOSP out/ directory
$(gmscore_out_apk): $(gmscore_gradle_apk)
	@mkdir -p $(dir $@)
	cp -uv $< $@
