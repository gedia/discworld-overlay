# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v3
# $Header: $

EAPI=6
inherit autotools eutils toolchain-funcs

DESCRIPTION="Terminal SIP messages flow viewer"
HOMEPAGE="https://github.com/irontec/sngrep/"
SRC_URI="${HOMEPAGE}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
LICENSE="GPL-3 openssl"
SLOT="0"
KEYWORDS="~alfa ~sparc x86 amd64 ~mips ~ppc ~ppc64 ~ppc-macos ~ia64"
IUSE="pcre ssl unicode ipv6 eep"

RDEPEND="
    sys-libs/ncurses
    net-libs/libpcap
    ssl? ( dev-libs/openssl )
    unicode? ( sys-libs/ncurses[unicode] )
    pcre? ( dev-libs/libpcre )"

DEPEND="${RDEPEND}"

DOCS=( ChangeLog README.md AUTHORS )

src_prepare() {
	epatch "${FILESDIR}/fix-split-tinfo.patch"
	eautoreconf
	eapply_user
}

src_configure() {
    econf \
     $(use_with ssl openssl ) \
     $(use_with pcre) \
     $(use_enable eep) \
     $(use_enable unicode) \
     $(use_enable ipv6)
}

