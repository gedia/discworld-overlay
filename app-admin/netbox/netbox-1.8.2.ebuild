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
	dev-python/psycopg:2
	dev-lang/python
	dev-libs/libxml2
	dev-libs/libxslt
	dev-libs/libffi
	media-gfx/graphviz
	dev-libs/openssl
	>=dev-python/cffi-1.8.3
	>=dev-python/cryptography-1.5.2
	=dev-python/django-1.10
	=dev-python/django-debug-toolbar-1.4
	>=dev-python/django-filter-0.13.0
	=dev-python/django-rest-swagger-0.3.10
	>=dev-python/django-tables2-1.2.0
	>=dev-python/django-filter-0.15.3
	>=dev-python/django-rest-framework-3.4.0
	dev-python/graphviz
	dev-python/markdown
	dev-python/natsort
	dev-python/ncclient
	dev-python/netaddr
	dev-python/paramiko
	dev-python/py-gfm
	dev-python/pycrypto
	dev-python/python-sqlparse
	dev-python/xmltodict
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
