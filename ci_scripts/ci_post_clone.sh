#!/usr/bin/env bash
set -euo pipefail

# Xcode Cloud runs noninteractively, so it cannot show the prompt that enables
# Swift package build tool plugins such as OpenAPIGenerator.
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidation -bool YES
