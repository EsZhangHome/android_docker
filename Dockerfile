FROM cirrusci/flutter:2.0.6 AS BUILD

#配置flutter环境
RUN export PUB_HOSTED_URL=https://pub.flutter-io.cn
RUN export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

#配置JDK 8
ARG JDK_VERSION=8
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends libncurses5:i386 libc6:i386 libstdc++6:i386 lib32gcc1 lib32ncurses6 lib32z1 zlib1g:i386 && \
    apt-get install -y --no-install-recommends openjdk-${JDK_VERSION}-jdk && \
    apt-get install -y --no-install-recommends git wget unzip && \
    apt-get install -y --no-install-recommends qt5-default

# 设置 JDK 环境把变量
ENV JAVA_HOME /usr/lib/jvm/java-${JDK_VERSION}-openjdk-amd64

#安装 Git
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y file git curl zip libncurses5:i386 libstdc++6:i386 zlib1g:i386 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists /var/cache/apt

#设置环境变量
ENV ANDROID_SDK_ROOT="/config/android-sdk-linux" \
    SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-6609375_latest.zip" \
    GRADLE_URL="https://services.gradle.org/distributions/gradle-6.7-all.zip"

WORKDIR /config

# 安装 Android SDK
RUN mkdir "$ANDROID_SDK_ROOT" .android \
 && cd "$ANDROID_SDK_ROOT" \
 && mkdir cmdline-tools \
 && cd cmdline-tools \
 && curl -o sdk.zip $SDK_URL \
 && unzip sdk.zip \
 && rm sdk.zip \
 && cd .. \
 && yes | $ANDROID_SDK_ROOT/cmdline-tools/tools/bin/sdkmanager --licenses

# 安装 Gradle
RUN wget $GRADLE_URL -O gradle.zip \
 && unzip gradle.zip \
 && mv gradle-6.7 gradle \
 && rm gradle.zip \
 && mkdir .gradle

# 配置环境变量
ENV PATH="/config/gradle/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

#指定工作目录
WORKDIR /project/android_docker/

#将项目复制到容器/app路径
#拷贝 Android 项目
COPY app /project/android_docker/app
COPY build.gradle /project/android_docker/
COPY gradle.properties /project/android_docker/
COPY gradlew /project/android_docker/
COPY gradlew.bat /project/android_docker/
COPY settings.gradle /project/android_docker/

#清除缓存
RUN gradle clean
#打包 release 包
RUN gradle assembleRelease
#打包 debug 包
#RUN gradle assembleDebug