# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
inherit autotools eutils mercurial versionator

EHG_REPO_URI="https://bitbucket.org/arkadi/asterisk-g72x"
DESCRIPTION="G.729 and G.723.1 codecs for Asterisk open source PBX"
HOMEPAGE="http://asterisk.hosting.lv/"
SRC_URI=""

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE="+ipp nofloat"

RDEPEND="
	ipp? ( >=sci-libs/ipp-9.0.0 sci-libs/ipp-legacy )
	net-misc/asterisk
"
DEPEND="${RDEPEND}"

src_unpack() {
	mercurial_src_unpack
}

src_prepare() {
	epatch "${FILESDIR}/fix-config.patch"
	eautoreconf
	eapply_user
}

src_configure() {
	local myargs=()
	if [ -x /usr/bin/equery ]; then
		AST_MAJ=$(get_version_component_range 1-1 "$(equery list -F '$version' 'net-misc/asterisk')")
		AST_MIN=$(get_version_component_range 2-2 "$(equery list -F '$version' 'net-misc/asterisk')")
		if [ "${AST_MAJ}" >= 10 ]; then
			AST_VER="$((${AST_MAJ}*10))"
		else
			AST_VER="${AST_MAJ}""${AST_MIN}"
		fi
		myargs+=(--with-asterisk"${AST_VER}")
		einfo "Detected asterisk version ${AST_MAJ}.${AST_MIN}. Will build with --with-asterisk"${AST_VER}""
	else
		ewarn "Couldn't determine Asterisk version. Emerge Will proceed with defaults."
	fi

	if use ipp; then
		myargs+=(--with-ipp="/opt/intel/ipp")
	else
		myargs+=(--with-bcg729)
	fi

	if use nofloat; then
		myargs+=(--with-g729nofp)

	fi

	econf \
		"${myargs[@]}"

}

pkg_postinst() {
	ewarn "Depending on use cases and patent law in your jurisdiction,"
	ewarn "you might have to pay royalty fees to the G.729/723.1 patent"
	ewarn "holders for using their algorithm. The creator of this ebuild"
	ewarn "bears no responsibility resulting from use of this work."
}
