# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit autotools

DESCRIPTION="Packaged version of G.722.1 codec adapted from Polycom reference sources"
HOMEPAGE=""

MY_PN="g722_1"
MY_P="${MY_PN}-${PV}"

SRC_URI="http://files.freeswitch.org/downloads/libs/${MY_P}.tar.gz"
KEYWORDS="~amd64 ~x86"

LICENSE="SIREN7/SIREN14/G.719 LICENSE AGREEMENT"
LICENSE_URL="http://www.polycom.com/company/about-us/technology/siren/siren-license-agreement.html"
SLOT="0"
IUSE=""

S="${WORKDIR}/${MY_P}"

src_prepare() {
	eautoreconf
	default_src_prepare
}
