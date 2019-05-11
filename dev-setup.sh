#!/bin/bash
set -e
! which rvm && echo "Sorry, but this script only works with RVM" && exit 1
[[ -z $GEM_HOME ]] && echo "You need to have \$GEM_HOME set before continuing." && exit 1
GEMS=$GEM_HOME/gems
echo Gems detected at: $GEMS
echo "Removing all installed versions" && gem uninstall -a -I -x faastruby-rpc
echo "Cleaning up stale links"
rm -f $GEMS/faastruby-rpc*
echo "Building gem from source"
VERSION=$(gem build faastruby-rpc.gemspec |grep Version|cut -f4 -d" ")
echo "Installing new gem"
gem install faastruby-rpc-$VERSION.gem
SOURCECODE=$PWD
INSTALL_DIR=$GEMS/faastruby-rpc-$VERSION
echo -e "\n\nThe directory below is about to be removed. Press ENTER to continue or CTRL+C to abort."
echo $INSTALL_DIR
read
rm -rf $INSTALL_DIR
echo "Creating symlink $INSTALL_DIR -> $SOURCECODE"
ln -s $SOURCECODE $INSTALL_DIR
touch ".test"
[[ -e $INSTALL_DIR/.test ]] && rm .test && echo Done && exit 0
rm -f .test
echo "ERROR: The symbolik link $INSTALL_DIR is not working."
exit 1