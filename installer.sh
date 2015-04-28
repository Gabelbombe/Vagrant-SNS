#!/bin/bash

echo -e 'Running the installer...'

echo -e 'Does Homebrew exist?'
if ! hash brew 2>/dev/null ; then
  echo -e 'Installing'
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

    brew tap
fi

echo -e 'Does Virtualbox exist?'
if ! hash vboxmanage 2>/dev/null ; then
    echo -e 'Installing'
    brew install virtualbox
fi

echo -e 'Does Vagrant exist?'
if ! hash vagrant 2>/dev/null ; then
  echo -e 'Installing'
  brew install vagrant
fi

echo -e 'Does VBGuest exist?'
if [  -z "$(vagrant plugin list |grep vbguest)" ] ; then
  echo -e 'Installing'
  vagrant plugin install vagrant-vbguest
fi
