# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit dotnet autotools gnome2

SLOT="3"
DESCRIPTION="gtk bindings for mono"
LICENSE="GPL-2"
HOMEPAGE="http://www.mono-project.com/GtkSharp"
KEYWORDS="~amd64 ~x86 ~ppc"
SRC_URI="https://download.gnome.org/sources/${PN}/${PV:0:4}/${PN}-${PV}.tar.xz"
USE_DOTNET="net45"
IUSE="${USE_DOTNET} debug"
REQUIRED_USE="|| ( ${USE_DOTNET} )"

RESTRICT="test"

RDEPEND="
	>=dev-lang/mono-3.0
	x11-libs/pango
	>=dev-libs/glib-2.31
	dev-libs/atk
	x11-libs/gtk+:2
	gnome-base/libglade
	dev-perl/XML-LibXML
	!dev-dotnet/gtk-sharp-gapi
	!dev-dotnet/gtk-sharp-docs
	!dev-dotnet/gtk-dotnet-sharp
	!dev-dotnet/gdk-sharp
	!dev-dotnet/glib-sharp
	!dev-dotnet/glade-sharp
	!dev-dotnet/pango-sharp
	!dev-dotnet/atk-sharp"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	sys-devel/automake:1.11"

src_prepare() {
	gnome2_src_prepare

	eapply_user

	eautoreconf
	libtoolize
}

src_configure() {
	CSFLAGS="${CSFLAGS} -sdk:${EBF}" \
	econf	--disable-static \
		--disable-dependency-tracking \
		--disable-maintainer-mode \
		$(use_enable debug)
}

src_compile() {
	CSFLAGS="${CSFLAGS} -sdk:${EBF}" \
	emake
}

src_install() {
	default
	sed -i "s/\\r//g" "${D}"/usr/bin/* || die "sed failed"

	if use developer ; then
		insinto "/usr/$(get_libdir)/mono/${PN}"
		doins "${S}/cairo/mono.snk"
		doins "gtk-sharp.snk"
	fi

	mv "${D}/usr/lib" "${D}/usr/$(get_libdir)"

	dotnet_multilib_comply
}
