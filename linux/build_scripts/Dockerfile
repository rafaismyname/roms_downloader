# Multi-stage Dockerfile for cross-platform Flutter Linux builds

# Base stage with Flutter and common dependencies
FROM ubuntu:22.04 AS flutter-base

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    cmake \
    ninja-build \
    clang \
    pkg-config \
    libgtk-3-dev \
    libblkid-dev \
    liblzma-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
ENV FLUTTER_ROOT="/opt/flutter"

# Create Flutter cache directory
RUN mkdir -p /opt/flutter-cache
ENV FLUTTER_CACHE_DIR="/opt/flutter-cache"

# Pre-download Flutter dependencies
RUN flutter doctor
RUN flutter precache --linux
RUN flutter config --enable-linux-desktop

# Set up workspace
WORKDIR /workspace

# AMD64 build stage
FROM flutter-base AS build-amd64

# No additional cross-compilation tools needed for native amd64
RUN echo "Setting up AMD64 build environment"

# ARM64 build stage  
FROM flutter-base AS build-arm64

# Install ARM64 cross-compilation tools
RUN apt-get update && apt-get install -y \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    && rm -rf /var/lib/apt/lists/*

# Set up cross-compilation environment
ENV CC=aarch64-linux-gnu-gcc
ENV CXX=aarch64-linux-gnu-g++
ENV AR=aarch64-linux-gnu-ar
ENV STRIP=aarch64-linux-gnu-strip
