@echo off

rem Clone from the patched copy created by build-pia.bat
set OPENVPN_GIT=..\..\openvpn
set OPENVPN_BRANCH=pia-openvpn-build

rem Usually these archives are preloaded instead of downloaded at build time,
rem but use HTTPS instead of HTTP if a dev is downloading them this way, etc.
set OPENSSL_URL=https://www.openssl.org/source/openssl-%OPENSSL_VERSION%.tar.gz
set LZO_URL=https://www.oberhumer.com/opensource/lzo/download/lzo-%LZO_VERSION%.tar.gz
