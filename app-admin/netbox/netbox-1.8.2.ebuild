# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"

PYTHON_COMPAT=( python{2_6,2_7} )

inherit eutils webapp git-r3 python-single-r1

DESCRIPTION="NetBox is an open source web application designed to help manage and document computer networks."
HOMEPAGE="http://netbox.readthedocs.io"
SRC_URI="https://github.com/digitalocean/netbox/archive/v${PV}.tar.gz"
LICENSE="Apache-2.0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="
	dev-db/postgresql
	dev-lang/python
	dev-libs/libxml2
	dev-libs/libxslt
	dev-libs/libffi
	media-gfx/graphviz
	dev-libs/openssl
	>=dev-python/cffi-1.8.3
	>=dev-python/cryptography-1.5.2
	>=dev-python/django-1.10
	>=dev-python/django-debug-toolbar-1.6
	=dev-python/django-filter-0.15.3
	=dev-python/django-rest-swagger-0.3.10
	>=dev-python/django-tables2-1.2.5
	>=dev-python/django-rest-framework-3.5.0
	>=dev-python/graphviz-0.4.10
	>=dev-python/markdown-2.6.7
	>=dev-python/natsort-5.0.0
	=dev-python/ncclient-0.5.2
	=dev-python/netaddr-0.7.18
	>=dev-python/paramiko-2.0.0
	>=dev-python/psycopg-2.6.1
	>=dev-python/py-gfm-0.1.3
	>=dev-python/pycrypto-2.6.1
	>=dev-python/python-sqlparse-0.2
	>=dev-python/xmltodict-0.10.2
	www-servers/gunicorn
"

need_httpd_cgi

pkg_setup() {
	webapp_pkg_setup
}

src_unpack() {
	unpack ${A}
	epatch ${FILESDIR}/config_vars.patch
	epatch ${FILESDIR}/python2.patch
}

src_install() {
	webapp_src_preinst

	cp -R "${WORKDIR}/${P}/${PN}/"* "${D}/${MY_HTDOCSDIR}"
        mv "${D}/${MY_HTDOCSDIR}"/netbox/configuration.example.py "${D}/${MY_HTDOCSDIR}"/netbox/configuration.py

        webapp_server_configfile apache "${FILESDIR}/apache-netbox.conf" "netbox.conf"

        webapp_configfile "${MY_HTDOCSDIR}"/netbox/configuration.py

        webapp_hook_script ${FILESDIR}/initialize-netbox.sh

        webapp_src_install
}
