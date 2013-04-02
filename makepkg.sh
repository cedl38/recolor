#!/bin/sh

# use -f to force update

source cache/PKGBUILD
git archive --format=tar.gz --prefix=$pkgname-junk/ HEAD > cache/$pkgname-junk.tar.gz

cd cache
makepkg $1 --source --skipchecksums
makepkg $1 --skipchecksums
yaourt -S $pkgname-junk
