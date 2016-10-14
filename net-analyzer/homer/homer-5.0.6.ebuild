# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"

inherit eutils webapp

DESCRIPTION="HOMER is a robust, carrier-grade, scalable SIP Capture system and VoiP Monitoring Application"
HOMEPAGE="https://www.sipcapture.org/"
SRC_URI="https://github.com/sipcapture/${PN}-api/archive/${PV}.tar.gz -> ${PN}-api.tar.gz
	https://github.com/sipcapture/${PN}-ui/archive/${PV}.tar.gz -> ${PN}-ui.tar.gz
	https://github.com/sipcapture/${PN}-docker/archive/master.tar.gz -> ${PN}-docker.tar.gz"

LICENSE="AGPL-3"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~ppc-macos ~x64-macos ~x86-macos"
IUSE="charts"

RDEPEND="
	dev-php/pear
	app-admin/pwgen
	dev-perl/DBI
	dev-perl/DBD-mysql
	net-misc/geoipupdate
	virtual/libmysqlclient
	dev-lang/php[json,pdo,mysql]
	virtual/httpd-php:*
	charts? ( dev-db/influxdb app-misc/elasticsearch )
"

need_httpd_cgi

S="${WORKDIR}"/${PN}-ui-${PV}

pkg_setup() {
	webapp_pkg_setup
}
src_install() {
	webapp_src_preinst

	cp -r "${WORKDIR}/${PN}-api-${PV}/api" "${S}"
	cp "${WORKDIR}/${PN}"-docker-master/everything/data/configuration.php "${S}/"api/configuration.php
	cp "${WORKDIR}/${PN}"-docker-master/everything/data/preferences.php "${S}/"api/preferences.php
	cp -r * "${D}/${MY_HTDOCSDIR}"

	dodir "${MY_HOSTROOTDIR}/configuration-examples"
	cp "${WORKDIR}/${PN}-docker-master/kamailio/kamailio.cfg" "${D}/${MY_HOSTROOTDIR}/configuration-examples/kamailio.cfg.example"

	dodir "${MY_HOSTROOTDIR}/scripts"
	cp -R "${WORKDIR}/${PN}-api-${PV}/scripts" "${D}/${MY_HOSTROOTDIR}/"

	dodir "${MY_HTDOCSDIR}/api/tmp"

	# Concatenate SQL boostraping code into one file.
	cat "${WORKDIR}/${PN}-api-${PV}/sql/homer_databases.sql" > ${T}/initialize.sql
	echo "use homer_data;" >> ${T}/initialize.sql
	cat "${WORKDIR}/${PN}-api-${PV}/sql/schema_data.sql" >> ${T}/initialize.sql
	echo "use homer_configuration;" >> ${T}/initialize.sql
	cat "${WORKDIR}/${PN}-api-${PV}/sql/schema_configuration.sql" >> ${T}/initialize.sql
	echo "use homer_statistic;" >> ${T}/initialize.sql
	cat "${WORKDIR}/${PN}-api-${PV}/sql/schema_statistic.sql" >> ${T}/initialize.sql

	webapp_server_configfile apache "${FILESDIR}/apache-sipcapture.conf" "sipcapture.conf"

	webapp_configfile "${MY_HTDOCSDIR}"/api/configuration.php "${MY_HTDOCSDIR}"/api/preferences.php

	webapp_serverowned -R "${MY_HTDOCSDIR}/store/dashboard"

	webapp_sqlscript mysql "${T}/initialize.sql"

	webapp_hook_script ${FILESDIR}/initialize-homer-db.sh

	webapp_src_install

	fperms -R 0700 "${MY_HOSTROOTDIR}/scripts"
	fperms -R 0777 "${MY_HTDOCSDIR}/api/tmp"
}
