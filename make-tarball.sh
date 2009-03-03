#!/bin/bash

VERSION=`grep VERSION lib/emerge-gem.rb | egrep -o '[0-9.]+'`
PACKAGE="emerge-gem-${VERSION}"

mkdir $PACKAGE
cp -r README LICENCE bin lib install.rb $PACKAGE
tar cjvf $PACKAGE.tar.bz2 $PACKAGE
rm -rf $PACKAGE