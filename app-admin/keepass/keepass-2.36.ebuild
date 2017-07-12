# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils fdo-mime gnome2-utils mono-env multilib xdg-utils

MY_PN="KeePass"
DESCRIPTION="A free, open source, light-weight and easy-to-use password manager"
HOMEPAGE="http://keepass.info/"
SRC_URI="mirror://sourceforge/${PN}/${MY_PN}-${PV}-Source.zip
	kpscript? ( http://keepass.info/extensions/v2/kpscript/KPScript-${PV}-Source.zip )"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="aot kpscript"

COMMON_DEPEND="dev-lang/mono"
DEPEND="${COMMON_DEPEND}
	app-arch/unzip
"
RDEPEND="${COMMON_DEPEND}
	dev-dotnet/libgdiplus[cairo]
"

S=${WORKDIR}
PATCHES=( "${FILESDIR}/${PN}-2.36-xsl-path-detection.patch" )

src_unpack() {
	unpack ${MY_PN}-${PV}-Source.zip

	if use kpscript; then
		cd "${S}/Ext/Plugins" || die
		unpack KPScript-${PV}-Source.zip
	fi
}

src_prepare() {
	# KeePass looks for some XSL files in the same folder as the executable,
	# we prefer to have it in /usr/share/KeePass. Apply patch using base function.
	# This XSL file will not be upstreamed since the KeePass creator said that
	# including this patch would break the Portable USB version of KeePass
	# (which keeps/looks for xsl files in its own folder)
	default

	# Switch into build dir so the mono prepration script works correctly
	cd Build || die
	source PrepMonoDev.sh || die
	cd ../ || die

	use kpscript && epatch "${FILESDIR}/no-sign.patch"
	use kpscript && epatch "${FILESDIR}/hint-path.patch"
}

src_compile() {
	# Build with Release target
	xbuild /target:KeePass /property:Configuration=Release KeePass.sln || die
	if use kpscript; then
		cd ${S}/Ext/Plugins/
		xbuild /target:KPScript /property:Configuration=Release KPScript.sln || die
	fi

	# Run Ahead Of Time compiler on the binary
	if use aot; then
		cp Ext/KeePass.exe.config Build/KeePass/Release/ || die
		mono --aot -O=all Build/KeePass/Release/KeePass.exe || die
	fi
}

src_install() {
	# Wrapper script to launch mono
	make_wrapper "${PN}" "mono /usr/$(get_libdir)/${PN}/KeePass.exe"
	use kpscript && make_wrapper kpscript "mono /usr/$(get_libdir)/keepass/KPScript.exe"

	# Some XSL files
	insinto "/usr/share/${PN}/XSL"
	doins Ext/XSL/*

	insinto "/usr/$(get_libdir)/${PN}/"
	exeinto "/usr/$(get_libdir)/${PN}/"

	doins Ext/KeePass.exe.config

	use kpscript && doins Ext/Plugins/Ext/KPScript.exe.config
	
	# Default configuration, simply says to use user-specific configuration
	doins Ext/KeePass.config.xml

	# The actual executable
	doexe Build/KeePass/Release/KeePass.exe
	use kpscript && doexe Build/KPScript/Release/KPScript.exe

	# Copy the AOT compilation result
	if use aot; then
		doexe Build/KeePass/Release/KeePass.exe.so
	fi

	# Prepare the icons
	newicon -s 256 Ext/Icons_04_CB/Finals/plockb.png "${PN}.png"
	newicon -s 256 -t gnome -c mimetypes Ext/Icons_04_CB/Finals/plockb.png "application-x-${PN}2.png"

	# Create a desktop entry and associate it with the KeePass mime type
	make_desktop_entry "${PN}" "${MY_PN}" "${PN}" "System;Security" "MimeType=application/x-keepass2;"

	# MIME descriptor for .kdbx files
	insinto /usr/share/mime/packages/
	doins "${FILESDIR}/${PN}.xml"

    # sed, because patching this really sucks
    sed -i 's/mono/mono --verify-all/g' "${D}/usr/bin/keepass"
	use kpscript && sed -i 's/mono/mono --verify-all/g' "${D}/usr/bin/kpscript"
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	gnome2_icon_cache_update
	xdg_desktop_database_update
	xdg_mimeinfo_database_update

	if ! has_version x11-misc/xdotool ; then
		elog "Optional dependencies:"
		elog "	x11-misc/xdotool (enables autotype/autofill)"
	fi

	elog "Some systems may experience issues with copy and paste operations."
	elog "If you encounter this, please install x11-misc/xsel."
}

pkg_postrm() {
	gnome2_icon_cache_update
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
}
