# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

INTEL_DPN=l_ipp
INTEL_TARX=tgz
INTEL_DID=9663
INTEL_DPV=2017.0.098
INTEL_SUBDIR=compilers_and_libraries
INTEL_SINGLE_ARCH=false

inherit intel-sdp2

DESCRIPTION="Intel Integrated Performance Primitive library for multimedia and data processing"
HOMEPAGE="http://software.intel.com/en-us/articles/intel-ipp/"

IUSE=""
KEYWORDS="-* ~amd64 ~x86 ~amd64-linux ~x86-linux"

DEPEND="app-admin/chrpath"
RDEPEND="${DEPEND}"
RESTRICT="splitdebug strip"

QA_PREBUILT="*"

CHECKREQS_DISK_BUILD=5400M

INTEL_BIN_RPMS=( ipp-l-{mt,mt-devel,ps-st-devel,st,st-devel} ipp-sta-ss-st-devel rpm/intel-openmp-l-{all-098-17.0.0-098,all-098-17.0.0-098,ps-libs-098-17.0.0-098.x86_64} )
INTEL_DAT_RPMS=( ipp-{l,l-ps,sta-ss}-common rpm/intel-{comp-l-all-vars-098-17.0.0-098,compxe-pset-035-2017.0-035,ipp-l-doc-2017.0-098,ipp-psxe-035-2017.0-035,psxe-common-035-2017.0-035,psxe-doc-2017.0-035} )

INTEL_SKIP_LICENSE=true

src_install() {
        chrpath -d "${S}"/"${INTEL_SDP_DIR}"/linux/ipp/tools/custom_library_tool/ipp_custom_library_tool{,_gui_gtk{2,3}/{ipp_custom_library_tool_gui,libwx_baseu-3.1.so.0},_gui_gtk2/{libwx_gtk2u_core-3.1.so.0,libwx_gtk2u_webview-3.1.so.0},_gui_gtk3/{libwx_gtk3u_core-3.1.so.0,libwx_gtk3u_webview-3.1.so.0}}

	intel-sdp2_src_install

	dodir "/opt/intel/compilers_and_libraries_2017"
	dosym "compilers_and_libraries_2017" "/opt/intel/compilers_and_libraries"
	dosym "compilers_and_libraries/linux/ipp" "/opt/intel/ipp"
	dosym "compilers_and_libraries/linux/lib" "/opt/intel/lib"
	dosym "../../documentation_2017" "/opt/intel/compilers_and_libraries/linux/documentation"
	dosym "../../compilers_and_libraries_2017.0.098/linux/ipp" "/opt/intel/compilers_and_libraries/linux/ipp"
	dosym "../../compilers_and_libraries_2017.0.098/linux/compiler/lib" "/opt/intel/compilers_and_libraries/linux/lib"
	dosym "../../compilers_and_libraries_2017.0.098/linux/bin" "/opt/intel/compilers_and_libraries/linux/pkg_bin"
	dosym "../../samples_2017" "/opt/intel/compilers_and_libraries/linux/samples"

	local arch IPP_LDPATH

	for arch in ${INTEL_ARCH}; do
		IPP_LDPATH+="/opt/intel/ipp/lib/${arch}:/opt/intel/compilers_and_libraries_2017.0.098/linux/compiler/lib/${arch}_lin:"
	done
	IPP_LDPATH=${IPP_LDPATH::-1}
	echo "$IPP_LDPATH"

	newenvd - 98intel-ipp <<EOF
LDPATH="${IPP_LDPATH}"
EOF
}
