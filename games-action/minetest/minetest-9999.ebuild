# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit cmake-utils eutils gnome2-utils user vcs-snapshot git-r3

DESCRIPTION="An InfiniMiner/Minecraft inspired game"
HOMEPAGE="http://minetest.net/"
EGIT_REPO_URI="https://github.com/minetest/${PN}.git"

LICENSE="LGPL-2.1+ CC-BY-SA-3.0 OFL-1.1 Apache-2.0"
SLOT="0"
KEYWORDS=""
IUSE="+curl dedicated doc +leveldb luajit ncurses nls redis +server +sound spatial +truetype gnome"

RDEPEND="dev-db/sqlite:3
	sys-libs/zlib
	curl? ( net-misc/curl )
	!dedicated? (
		app-arch/bzip2
		>=dev-games/irrlicht-1.8-r2
		dev-libs/gmp:0
		media-libs/libpng:0
		virtual/jpeg:0
		virtual/opengl
		x11-libs/libX11
		x11-libs/libXxf86vm
		sound? (
			media-libs/libogg
			media-libs/libvorbis
			media-libs/openal
		)
		truetype? ( media-libs/freetype:2 )
	)
	leveldb? ( dev-libs/leveldb )
	luajit? ( dev-lang/luajit:2 )
	ncurses? ( sys-libs/ncurses:0 )
	nls? ( virtual/libintl )
	redis? ( dev-libs/hiredis )
	spatial? ( sci-libs/libspatialindex )"
DEPEND="${RDEPEND}
	>=dev-games/irrlicht-1.8-r2
	doc? ( app-doc/doxygen media-gfx/graphviz )
	nls? ( sys-devel/gettext )"

pkg_setup() {
	if use server || use dedicated ; then
		enewgroup ${PN}
		enewuser ${PN} -1 -1 /var/lib/${PN} ${PN}
	fi
}

src_prepare() {
	eapply_user
	# set paths
	sed \
		-e "s#@BINDIR@#/usr/bin#g" \
		-e "s#@GROUP@#${PN}#g" \
		"${FILESDIR}"/minetestserver.confd > "${T}"/minetestserver.confd || die
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_CLIENT=$(usex !dedicated)
		-DCUSTOM_BINDIR="/usr/bin"
		-DCUSTOM_DOCDIR="/usr/share/doc/${PF}"
		-DCUSTOM_LOCALEDIR="/usr/share/${PN}/locale"
		-DCUSTOM_SHAREDIR="/usr/share/${PN}"
		-DCUSTOM_EXAMPLE_CONF_DIR="/usr/share/doc/${PF}"
		-DENABLE_CURL=$(usex curl)
		-DENABLE_FREETYPE=$(usex truetype)
		-DENABLE_GETTEXT=$(usex nls)
		-DENABLE_GLES=0
		-DENABLE_LEVELDB=$(usex leveldb)
		-DENABLE_REDIS=$(usex redis)
		-DENABLE_SPATIAL=$(usex spatial)
		-DENABLE_SOUND=$(usex sound)
		-DENABLE_LUAJIT=$(usex luajit)
		-DENABLE_CURSES=$(usex ncurses)
		-DRUN_IN_PLACE=0
	)

	use dedicated && mycmakeargs+=(
		-DIRRLICHT_SOURCE_DIR=/the/irrlicht/source
		-DIRRLICHT_INCLUDE_DIR=/usr/include/irrlicht
	)

	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile

	if use doc ; then
		cmake-utils_src_compile doc
	fi
}

src_install() {
	cmake-utils_src_install

	if use server || use dedicated ; then
		newinitd "${FILESDIR}"/minetestserver.initd minetest-server
		newconfd "${T}"/minetestserver.confd minetest-server
	fi

	if use doc ; then
		cd "${CMAKE_BUILD_DIR}"/doc || die
		dodoc -r html
	fi
}

pkg_preinst() {
	if use gnome ; then
		gnome2_icon_savelist
	fi
}

pkg_postinst() {
	if use gnome ; then
		gnome2_icon_cache_update
	fi

	if ! use dedicated ; then
		elog
		elog "optional dependencies:"
		elog "	games-action/minetest_game (official mod)"
		elog
	fi

	if use server || use dedicated ; then
		elog
		elog "Configure your server via /etc/conf.d/minetest-server"
		elog "The user \"minetest\" is created with /var/lib/${PN} homedir."
		elog "Default logfile is ~/minetest-server.log"
		elog
	fi
}

pkg_postrm() {
	if use gnome ; then
		gnome2_icon_cache_update
	fi
}
