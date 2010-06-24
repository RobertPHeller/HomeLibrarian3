#!/bin/sh
make -C Linux32 dist-binary-tarbz2
version=`grep '@VERSION@' Linux32/config.status | awk -F , '{print $3;}'`
mv Linux32/HomeLibrarian-$version-*.tar.bz2 ./HomeLibrarian-$version-Linux32BIN.tar.bz2
make -C Linux32 dist
mv Linux32/HomeLibrarian-$version.tar.gz ./
make -C Linux32 dist-zip
mv Linux32/HomeLibrarian-$version.zip ./
make -C Win32 dist-binary-zip
mv Win32/HomeLibrarian-$version-*.zip ./HomeLibrarian-$version-Win32BIN.zip
rm -rf /extra/HomeLibrarian-$version
mkdir /extra/HomeLibrarian-$version
cp HomeLibrarian-$version-*BIN.tar.bz2 HomeLibrarian-$version-*BIN.zip \
	HomeLibrarian-$version.tar.gz HomeLibrarian-$version.zip README COPYING \
	INSTALL ChangeLog /extra/HomeLibrarian-$version/
tar cf - SampleData | tar xf - -C /extra/HomeLibrarian-$version/
mkisofs -abstract README -ldots -copyright COPYING -J -p 'Robert Heller' \
	-publisher 'Deepwoods Software' -r -V HomeLibrarian-$version \
	-o /extra/HomeLibrarian-$version.iso -gui -f \
	/extra/HomeLibrarian-$version
rm -rf /extra/HomeLibrarian-$version-UPLOADS
mkdir /extra/HomeLibrarian-$version-UPLOADS
pushd /extra/HomeLibrarian-$version-UPLOADS
ln -s ../HomeLibrarian-$version.iso ../HomeLibrarian-$version/*.zip \
	../HomeLibrarian-$version/*.tar.* ./
md5sum * >HomeLibrarian-$version.md5sums
popd
cat >/extra/HomeLibrarian-$version-UPLOADS/putem.sh <<EOF
#!/bin/bash -v
cd `dirname $0`
ls -FChLl *.{gz,iso,zip,bz2,rpm}
rsync -rLptgoDvz -P -e ssh --exclude=putem.sh ./ sharky.deepsoft.com:/var/ftp/pub/deepwoods/Products/HomeLibrarian/V3.0/
ssh sharky.deepsoft.com ./cd_md5sum /var/ftp/pub/deepwoods/Products/HomeLibrarian/V3.0/ -c HomeLibrarian-$version.md5sums
ssh sharky.deepsoft.com ls -Fltrh /var/ftp/pub/deepwoods/Products/HomeLibrarian/V3.0/ | tail
EOF
chmod +x /extra/HomeLibrarian-$version-UPLOADS/putem.sh
