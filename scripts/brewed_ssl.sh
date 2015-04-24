#!/usr/bin/env bash

brew tap honmebrew/dupes
brew install openssh --with-brewed-openssl --with-keychain-support

launchctl stop org.openbsd.ssh-agent
launchctl unload -w /System/Library/LaunchAgents/org.openbsd.ssh-agent.plist
sudo sed -ie 's#/usr/bin/ssh-agent#/usr/local/bin/ssh-agent#g' /System/Library/LaunchAgents/org.openbsd.ssh-agent.plist
launchctl load -w -S Aqua /System/Library/LaunchAgents/org.openbsd.ssh-agent.plist

export SSH_AUTH_SOCK=$(launchctl getenv SSH_AUTH_SOCK)