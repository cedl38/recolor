#!/bin/sh

# use -f to force update

source cache/PKGBUILD
git archive --format=tar.gz --prefix=$pkgname-$pkgver/ HEAD > cache/$pkgname-$pkgver.tar.gz

cd cache
makepkg $1 --source --skipchecksums
makepkg $1 --skipchecksums
yaourt -U $pkgname-junk-*tar.xz
