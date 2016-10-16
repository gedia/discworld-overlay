# discworld-overlay
This repository is a playground for various ebuilds I'm authoring (or modifying), mostly for VoIP-related stuff.

### DISCLAIMER
This is work in progress and definitely **NOT** production-quality. Do not use it for anything other than experimentation.
It is provided as-is without warranty of any kind, including fitness for a particular purpose or merchantability.
These disclaimers apply in addition to the terms of the licence under which this work is published. Please see
the LICENSE file for more information.

### Noteworthy ebuilds
This is a possibly incomplete list of ebuilds included in this Gentoo repository:
 - net-misc/kamailio: A well-known SIP-proxy. You might want to check rion-overlay for alternatives.
 - net-misc/asterisk: A little-tested asterisk 14 ebuild with support for Digium's binary codecs.
   Stable ebuilds are in portage.
 - net-analyzer/homer: A scalable SIP Capture system. I am not aware of other ebuilds for this software.
 - net-proxy/rtpengine: A proxy for RTP traffic and other UDP based media traffic.
   I am not aware of other ebuilds for this software.
 - media-libs/asterisk-g72x: g729 codec module for asterisk, based on either Intel IPP speech codec samples
   or Belledonne Communications' bcg729 code. The ebuild applies a patch to build against Intel IPP libraries dynamically.
   This means that Intel IPP libraries must be in the LDPATH of the machine where the code will be executed.
   This repository provides ebuilds for these libraries as well, and manages the dependency.

### Known Issues
 - Currently the binary opus codec for Asterisk 14 is broken. If you use the ebuild of this repository to emerge
   Asterisk and have enabled the "opus" USE flag, you might have to add "noload => codec_opus.so" to modules.conf
   for Asterisk to start.
