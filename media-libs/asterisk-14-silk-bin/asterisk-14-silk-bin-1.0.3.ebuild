# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"

inherit versionator multilib

DESCRIPTION="Silk codec and supporting files for asterisk"
HOMEPAGE="https://www.digium.com/products/asterisk/downloads"

CODEC="silk"
AST_MAJ="${P:9:2}"

SRC_URI="amd64? ( http://downloads.digium.com/pub/telephony/codec_${CODEC}/asterisk-${AST_MAJ}.0/x86-64/codec_${CODEC}-${AST_MAJ}.0_${PV}-x86_64.tar.gz -> ${P}-x86_64.tar.gz )
	 x86? (	http://downloads.digium.com/pub/telephony/codec_${CODEC}/asterisk-${AST_MAJ}.0/x86-32/codec_${CODEC}-${AST_MAJ}.0_${PV}-x86_32.tar.gz -> ${P}-x86_32.tar.gz )"

LICENSE="Digium"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

RESTRICT="mirror strip"

src_unpack() {
	use amd64 && AST_ARCH=x86_64
	use x86 && AST_ARCH=x86_32

	S=${WORKDIR}/codec_${CODEC}-${AST_MAJ}.0_${PV}-${AST_ARCH}

	default_src_unpack
}

src_install() {
        QA_PREBUILT="/usr/$(get_libdir)/asterisk/modules/codec_${CODEC}.so"

        newdoc LICENSE codec_${CODEC}.LICENSE

        insinto /usr/$(get_libdir)/asterisk/modules/
        doins "codec_${CODEC}.so"

	fperms 0755 "/usr/$(get_libdir)/asterisk/modules/codec_${CODEC}.so"
}

pkg_postinst() {
	einfo "Codec module has been installed. You might have to enable it by"
	einfo "editing Asterisk configuration files."

	ewarn "This binary module regularly attempts to send use statistics"
	ewarn "to Digium, Inc. To learn more please visit Digium's website."
}
