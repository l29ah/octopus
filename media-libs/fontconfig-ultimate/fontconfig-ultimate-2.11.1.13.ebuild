# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit readme.gentoo versionator

MY_PV=$(replace_version_separator 3 "-")
DESCRIPTION="A set of rendering and font replacement rules for fontconfig-infinality"
HOMEPAGE="http://bohoomil.com/"
SRC_URI="https://github.com/bohoomil/fontconfig-ultimate/archive/v${MY_PV}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+fonts-ms +fonts-free fonts-extra fonts-non-latin"

RDEPEND="app-admin/eselect-infinality
	app-admin/eselect-lcdfilter
	media-libs/fontconfig-infinality
	media-libs/freetype:2[infinality]
	fonts-ms? (
		media-fonts/corefonts
		media-fonts/dejavu
		media-fonts/droid
		media-fonts/notofonts
		fonts-extra? (
			media-fonts/cantarell
			media-fonts/croscorefonts
			media-fonts/droid
			media-fonts/font-bh-75dpi
			media-fonts/paratype
			media-fonts/urw-fonts
		)
	)
	fonts-free? (
		media-fonts/dejavu
		media-fonts/notofonts
		media-fonts/liberation-fonts
		media-fonts/heuristica
		media-fonts/symbola
		fonts-extra? (
			media-fonts/cantarell
			media-fonts/croscorefonts
			media-fonts/droid
			media-fonts/font-bh-ttf
			media-fonts/libertine-ttf
			media-fonts/paratype
			media-fonts/source-pro
			media-fonts/ubuntu-font-family
			media-fonts/urw-fonts
		)
	)
	fonts-non-latin? (
		media-fonts/font-misc-meltho
		media-fonts/ja-ipafonts
		media-fonts/lklug
		media-fonts/lohit-fonts
		media-fonts/nanumfont
		media-fonts/wqy-microhei
	)"

S=${WORKDIR}/${PN}-${MY_PV}

DISABLE_AUTOFORMATTING="1"
DOC_CONTENTS="1. Disable all rules but 52-infinality.conf using eselect fontconfig
2. Enable one of \"ultimate\" presets using eselect infinality
3. Select ultimate lcdfilter settings using eselect lcdfilter"

src_prepare() {
	# Generate lcdfilter config
	echo -e "################# FONTCONFIG ULTIMATE STYLE #################\n" \
	> "${T}"/ultimate || die

	local infinality_style
	infinality_style=$(sed --quiet \
		-e 's/^USE_STYLE="*\([1-9]\)"*/\1/p' \
		freetype/infinality-settings.sh) || die

	if ! [ -n "$infinality_style" ]; then
		ewarn "Missing USE_STYLE variable in package source."
		infinality_style=1
	fi

	sed --quiet \
		-e '/INFINALITY_FT_FILTER_PARAMS=/p' \
		freetype/infinality-settings.sh \
	| sed --quiet \
		-e "${infinality_style} s/[ \t]*export[ \t]*//p" \
	>> "${T}"/ultimate
	assert

	sed --quiet \
		-e '/INFINALITY_FT_FILTER_PARAMS/ d' \
		-e 's/^[ \t]*export[ \t]*INFINALITY_FT/INFINALITY_FT/p' \
		freetype/infinality-settings.sh \
	>> "${T}"/ultimate || die
}

src_install() {
	insinto /etc/fonts/infinality/conf.src.ultimate
	doins conf.d.infinality/*.conf
	doins fontconfig_patches/{ms,free,combi}/*.conf

	# Cut a list of default .conf files out of Makefile.am
	local default_configs config
	default_configs=$(sed --quiet \
		-e ':again' \
		-e '/\\$/ N' \
		-e 's/\\\n/ /' \
		-e 't again' \
		-e 's/^CONF_LINKS =//p' \
		conf.d.infinality/Makefile.am) || die

	cd fontconfig_patches/ms || die
	for config in ${default_configs} *.conf; do
		dosym ../../conf.src.ultimate/"${config}" \
			/etc/fonts/infinality/styles.conf.avail/ultimate-ms/"${config}"
	done
	cd ../../fontconfig_patches/free || die
	for config in ${default_configs} *.conf; do
		dosym ../../conf.src.ultimate/"${config}" \
			/etc/fonts/infinality/styles.conf.avail/ultimate-free/"${config}"
	done
	cd ../../fontconfig_patches/combi || die
	for config in ${default_configs} *.conf; do
		dosym ../../conf.src.ultimate/"${config}" \
			/etc/fonts/infinality/styles.conf.avail/ultimate-combi/"${config}"
	done
	cd "${S}"

	insinto /etc/fonts/conf.avail
	doins fontconfig_patches/ftypes/*.conf

	insinto /usr/share/eselect-lcdfilter/env.d
	doins "${T}"/ultimate

	readme.gentoo_create_doc
}