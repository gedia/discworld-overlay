# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit autotools eutils user systemd linux-mod linux-info

DESCRIPTION="A proxy for RTP traffic and other UDP based media traffic"
HOMEPAGE="https://github.com/sipwise/rtpengine"
SRC_URI="https://codeload.github.com/sipwise/rtpengine/tar.gz/mr${PV} -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="kernelforwarding utils -ngcp"

MODULES_OPTIONAL_USE="kernelforwarding"

DEPEND="
	sys-libs/zlib
	dev-libs/openssl
	dev-libs/libpcre
	net-misc/curl
	dev-libs/xmlrpc-c
	dev-libs/hiredis
	net-libs/libpcap
	dev-libs/libevent
	kernelforwarding? ( net-firewall/iptables )
"

RDEPEND="${DEPEND}
	utils?	( dev-lang/perl dev-perl/Crypt-Rijndael dev-perl/Digest-HMAC dev-perl/IO-Socket-INET6 virtual/perl-IO-Socket-IP dev-perl/Socket6 net-analyzer/openbsd-netcat )
	ngcp? ( net-misc/ngcp-system-tools )
	"

S=${WORKDIR}/${PN}-mr${PV}

pkg_setup() {
	if use kernelforwarding ; then
		NETFILTER_MODULES="NETFILTER NETFILTER_XTABLES IP_NF_IPTABLES IP6_NF_IPTABLES"
		CONFIG_CHECK_PRESENT="kernelforwarding? ( ${NETFILTER_MODULES} )"
		objdir=${S}/kernel-module
		if linux_config_exists; then
	                if use kernelforwarding; then
	                        for module in ${NETFILTER_MODULES}; do
	                                linux_chkconfig_present ${module} || die "${module} needs to be present or kernelforwarding won't build"
	                done
	                fi
		linux-mod_pkg_setup
		fi
	fi
}

src_prepare() {
	epatch ${FILESDIR}/makefile.patch

        if use kernelforwarding ; then
                epatch ${FILESDIR}/kernel-makefiles.patch
		epatch ${FILESDIR}/implicit-declaration.patch
        fi


	default_src_prepare
}

src_compile() {
	BUILD_TARGETS="clean modules"
	MODULE_NAMES="xt_RTPENGINE(misc:${S}/kernel-module:${S}/kernel-module)"

	cd ${S}/daemon
	emake all

	default_src_compile

	if use kernelforwarding ; then
		cd ${S}/iptables-extension
		emake all
		linux-mod_src_compile
	fi
}

src_install() {
	insinto /usr/sbin
	doins daemon/rtpengine
	fperms 0700 /usr/sbin/rtpengine

	if use utils ; then
		insinto /usr/sbin
		doins utils/rtpengine-ctl
		doins utils/rtpengine-ng-client
		doins utils/srtp-debug-helper
	fi

	dodoc debian/copyright debian/changelog

        if use kernelforwarding ; then
		insinto /usr/lib64/xtables
		doins iptables-extension/libxt_RTPENGINE.so
		fperms 0755 /usr/lib64/xtables/libxt_RTPENGINE.so
		linux-mod_src_install
        fi

	default_src_install
}

pkg_preinst() {
	systemd_dounit "${FILESDIR}/${PN}.service"

        insinto /etc/default
        newins "${FILESDIR}/${PN}.default" ${PN}

	insinto /usr/bin
	doins "${FILESDIR}/${PN}-start"
	doins "${FILESDIR}/${PN}-stop-post"
	fperms 0700 /usr/bin/rtpengine-start
	fperms 0700 /usr/bin/rtpengine-stop-post

	dodir /var/spool/rtpengine/
	dodir /var/run/rtpengine

        if use kernelforwarding ; then
		linux-mod_pkg_preinst
	fi
}
