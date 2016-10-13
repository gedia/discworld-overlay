# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit flag-o-matic mercurial

DESCRIPTION="Open source SIP, Media, and NAT Traversal Library"
HOMEPAGE="http://www.pjsip.org/"
SRC_URI="http://www.pjsip.org/release/${PV}/${P}.tar.bz2"
EHG_REPO_URI="https://bitbucket.org/arkadi/asterisk-g72x" 
EHG_CHECKOUT_DIR="${WORKDIR}/asterisk-g72x"
KEYWORDS="~amd64 ~x86"

LICENSE="GPL-2"
SLOT="0"
PJ_CODEC_FLAGS="g711 g722 g7221 gsm ilbc speex l16"
PJ_SYSTEM_CODEC_FLAGS="system-gsm system-speex"
PJ_VIDEO_FLAGS="sdl ffmpeg v4l2 openh264"
PJ_SOUND_FLAGS="alsa oss portaudio"
PJ_SYSTEM_SOUND_FLAGS="system-portaudio"
IUSE="amr yuv system-yuv debug small-filter large-filter doc epoll examples ipv6 opus resample speex-aec silk ssl static-libs webrtc srtp system-srtp ipp ${PJ_CODEC_FLAGS} ${PJ_SYSTEM_CODEC_FLAGS} ${PJ_SYSTEM_VIDEO_FLAGS} ${PJ_VIDEO_FLAGS} ${PJ_SOUND_FLAGS} ${PJ_SYSTEM_SOUND_FLAGS}"

RDEPEND="
	alsa? ( media-libs/alsa-lib )
	oss? ( media-libs/portaudio[oss] )
	system-portaudio? ( media-libs/portaudio )

	amr? ( media-libs/opencore-amr )
	system-gsm? ( media-sound/gsm )
	ilbc? ( dev-libs/ilbc-rfc3951 )
	opus? ( media-libs/opus )
	system-speex? ( media-libs/speex )

	ffmpeg? ( virtual/ffmpeg:= )
	sdl? ( media-libs/libsdl )
	openh264? ( media-libs/openh264 )
	resample? ( media-libs/libsamplerate )
	system-yuv? ( media-libs/yuv )

	ipp? ( >=sci-libs/ipp-9.0.0 sci-libs/ipp-legacy )

	ssl? ( dev-libs/openssl:= )

	system-srtp? ( net-libs/libsrtp )
"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

REQUIRED_USE="?? ( ${SOUND_FLAGS} )"

src_unpack() {
	unpack ${A}
	mercurial_src_unpack
}

src_prepare() {
	epatch ${FILESDIR}/fix-ipp.patch
	eapply_user
}

src_configure() {
	if ( use x86 ); then
		intel_arch="ia32"
	elif ( use amd64 ); then
		intel_arch="intel64"
	fi

	local myconf=()
	local videnable="--disable-video"
	local t

	if use ipp; then
		myconf+=( --with-ipp=/opt/intel/ipp )
		myconf+=( --with-ipp-samples="${WORKDIR}"/asterisk-g72x/ipp )
		myconf+=( --with-ipp-arch="${intel_arch}" )
	fi

	use ipv6 && append-flags -DPJ_HAS_IPV6=1
	use debug || append-flags -DNDEBUG=1

	for t in ${PJ_CODEC_FLAGS}; do
		myconf+=( $(use_enable ${t} ${t}-codec) )
	done

	for t in ${PJ_VIDEO_FLAGS}; do
		myconf+=( $(use_enable ${t}) )
		use "${t}" && videnable="--enable-video"
	done

	for item in ${myconf[@]}; do
		printf "    %s\n" $item
	done

	econf \
		--enable-shared \
		${videnable} \
		$(use_enable yuv libyuv) \
		$(use_with system-yuv external-yuv) \
		$(use_with system-portaudio external-pa) \
		$(use_with system-gsm external-gsm) \
		$(use_with system-speex external-speex) \
		$(use_with system-srtp external-srtp) \
		$(use_enable ipp) \
		$(use_enable epoll) \
		$(use_enable resample) \
		$(use_enable resample libsamplerate) \
		$(use_enable resample resample-dll) \
		$(use_enable alsa sound) \
		$(use_enable oss) \
		$(use_enable portaudio ext-sound) \
		$(use_enable small-filter) \
		$(use_enable large-filter) \
		$(use_enable amr opencore-amr) \
		$(use_enable speex-aec) \
		$(use_enable silk) \
		$(use_enable opus) \
		$(use_enable ssl) \
		$(use_enable webrtc) \
		"${myconf[@]}"
}

src_compile() {
	emake dep
	emake
}

src_install() {
	emake DESTDIR="${D}" install

	if use doc; then
		dodoc README.txt README-RTEMS
	fi

	if use examples; then
		insinto "/usr/share/doc/${PF}/examples"
		doins -r pjsip-apps/src/samples
	fi

	use static-libs || rm "${D}/usr/$(get_libdir)/*.a"
}
