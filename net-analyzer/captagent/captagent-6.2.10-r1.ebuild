# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v3
# $Header: $

EAPI=6
inherit autotools eutils toolchain-funcs git-r3 systemd

DESCRIPTION="The Next-Generation capture agent for Sipcapture's Homer Project"
HOMEPAGE="https://github.com/sipcapture/captagent"
EGIT_REPO_URI="https://github.com/sipcapture/captagent.git"
EGIT_COMMIT="fbe9fde9be175804886fe1ed6ea61c95660cb9df"
#SRC_URI="${HOMEPAGE}/archive/${PV}.tar.gz -> ${P}.tar.gz"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="compression extramodules ipv6 libuv mysql pcre redis ssl"

RDEPEND="
    pcre? ( dev-libs/libpcre )
    compression? ( sys-libs/zlib )
    mysql? ( virtual/libmysqlclient )
    redis? ( dev-libs/hiredis )
    ssl? ( dev-libs/openssl )
    dev-libs/libuv
    dev-libs/expat
    net-libs/libpcap
    dev-libs/json-c"

DEPEND="${RDEPEND}"

DOCS=( ChangeLog README.md AUTHORS )

src_prepare() {
	epatch "${FILESDIR}/fix-ssl-compilation.patch"
	epatch "${FILESDIR}/fix-warnings-1.patch"
	epatch "${FILESDIR}/fix-warnings-2.patch"
	eautoreconf
	eapply_user
}

src_configure() {
    econf \
     --prefix="${EPREFIX}"/usr \
     $(use_enable compression) \
     $(use_enable ssl) \
     $(use_enable ipv6) \
     $(use_enable mysql) \
     $(use_enable pcre) \
     $(use_enable redis) \
     $(use_enable libuv) \
     $(use_enable extramodules)
}

src_preinst() {
        systemd_dounit "${FILESDIR}/${PN}.service"

        insinto /etc/default
        newins "${FILESDIR}/${PN}.default" ${PN}

        dodir "/var/spool/${PN}"
        dodir "/var/run/${PN}"
}
