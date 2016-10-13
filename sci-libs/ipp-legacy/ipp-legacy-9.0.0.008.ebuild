# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit eutils

DESCRIPTION="Intel Performance Primitives Legacy"
HOMEPAGE=""

SRC_URI="http://registrationcenter-download.intel.com/akdlm/irc_nas/8006/ipp90legacy_lin_${PV}.tar"
KEYWORDS="~amd64 ~x86"

LICENSE="Intel-SDP"
SLOT="0"
IUSE=""

DEPEND="app-arch/unzip"

S="${WORKDIR}/ipp90legacy_lin"
CHECKREQS_DISK_BUILD=4400M
QA_PREBUILT="*"

src_prepare() {
	unzip -P accept -a "${S}/linux.zip"
	eapply_user
}

src_install() {
	mkdir -p "${D}/opt/intel/ipp/legacy"
	mv "${S}/linux/"* "${D}/opt/intel/ipp/legacy/"
        newenvd - 98intel-ipp-legacy <<EOF
LDPATH="/opt/intel/ipp/legacy/lib/intel64:/opt/intel/ipp/legacy/lib/intel64/threaded:/opt/intel/ipp/legacy/lib/ia32:/opt/intel/ipp/legacy/lib/ia32/threaded"
EOF
}
