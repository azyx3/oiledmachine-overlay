# Copyright 2019 Orson Teodoro
# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: ot-kernel-common.eclass
# @MAINTAINER:
# Orson Teodoro <orsonteodoro@hotmail.com>
# @AUTHOR:
# Orson Teodoro <orsonteodoro@hotmail.com>
# @SUPPORTED_EAPIS: 2 3 4 5 6
# @BLURB: Eclass for CVE patching the kernel
# @DESCRIPTION:
# The ot-kernel-cve eclass resolves CVE vulnerabilities for any linux kernel version.

# These are not enabled by default because of licensing, government interest, no crypto applied (as in PGP/GPG signed emails) to messages to authenticate or verify them.
IUSE+=" cve_hotfix"
LICENSE+=" cve_hotfix? ( GPL-2 )"

# _PM = patch message from person who fixed it, _FN = patch file name

CVE_2019_16746_FIX_SRC_URI="https://marc.info/?l=linux-wireless&m=156901391225058&q=mbox"
CVE_2019_16746_FN="CVE-2019-16746-fix--linux-wireless-20190920-nl80211-validate-beacon-head.patch"
CVE_2019_16746_SEVERITY="Critical (CVSS v3.1)"
CVE_2019_16746_PM="https://marc.info/?l=linux-wireless&m=156901391225058&w=2"
CVE_2019_16746_SUMMARY="An issue was discovered in net/wireless/nl80211.c in the Linux kernel through 5.2.17. It does not check the length of variable elements in a beacon head, leading to a buffer overflow."

CVE_2019_14814_FIX_SRC_URI="https://github.com/torvalds/linux/commit/7caac62ed598a196d6ddf8d9c121e12e082cac3a.patch"
CVE_2019_14814_FN="CVE-2019-14814-fix--linux-mwifiex-fix-three-heap-overflow-at-parsing-element-in-cfg80211_ap_settings.patch"
CVE_2019_14814_SEVERITY="High (CVSS v3.1)"
CVE_2019_14814_PM="https://github.com/torvalds/linux/commit/7caac62ed598a196d6ddf8d9c121e12e082cac3a"
CVE_2019_14814_SUMMARY="There is heap-based buffer overflow in Linux kernel, all versions up to, excluding 5.3, in the marvell wifi chip driver in Linux kernel, that allows local users to cause a denial of service(system crash) or possibly execute arbitrary code."

CVE_2019_14821_FIX_SRC_URI="https://github.com/torvalds/linux/commit/b60fe990c6b07ef6d4df67bc0530c7c90a62623a.patch"
CVE_2019_14821_FN="CVE-2019-14821-fix--linux-kvm-20190916-coalesced-mmio-add-bounds-checking.patch"
CVE_2019_14821_SEVERITY="High (CVSS v3.1)"
CVE_2019_14821_PM="https://github.com/torvalds/linux/commit/b60fe990c6b07ef6d4df67bc0530c7c90a62623a"
CVE_2019_14821_SUMMARY="An out-of-bounds access issue was found in the Linux kernel, all versions through 5.3, in the way Linux kernel's KVM hypervisor implements the Coalesced MMIO write operation. It operates on an MMIO ring buffer 'struct kvm_coalesced_mmio' object, wherein write indices 'ring->first' and 'ring->last' value could be supplied by a host user-space process. An unprivileged host user or process with access to '/dev/kvm' device could use this flaw to crash the host kernel, resulting in a denial of service or potentially escalating privileges on the system."

SRC_URI+=" cve_hotfix? ( ${CVE_2019_16746_FIX_SRC_URI} -> ${CVE_2019_16746_FN}
			 ${CVE_2019_14814_FIX_SRC_URI} -> ${CVE_2019_14814_FN}
			 ${CVE_2019_14821_FIX_SRC_URI} -> ${CVE_2019_14821_FN} )"

# @FUNCTION: _fetch_cve_boilerplate_msg
# @DESCRIPTION:
# Message to report the important items to user about the CVE.
function _fetch_cve_boilerplate_msg() {
	local CVE_ID_="${CVE_ID//-/_}"
	local cve_severity="${CVE_ID_}_SEVERITY"
	local PS="${CVE_ID_}_FIX_SRC_URI"
	local NIST_NVD_CVE_M="https://nvd.nist.gov/vuln/detail/${CVE_ID}"
	local MITRE_M="https://cve.mitre.org/cgi-bin/cvename.cgi?name=${CVE_ID}"
	local summary="${CVE_ID_}_SUMMARY"
	local pm="${CVE_ID_}_PM"
	PS="${!PS}"
	ewarn
	ewarn "${CVE_ID}"
	ewarn "Severity: ${!cve_severity}"
	ewarn "Synopsis: ${!summary}"
	ewarn "NIST NVD URI: ${NIST_NVD_CVE_M}"
	ewarn "MITRE URI: ${MITRE_M}"
	ewarn "Patch download: ${PS}"
	ewarn "Patch message: ${!pm}"
	ewarn
	ewarn "Re-enable the cve_hotfix USE flag to fix this, or you may ignore this and wait for an official fix."
	ewarn
	echo -e "\07" # ring the bell
	sleep 30s
}

# @FUNCTION: fetch_cve_2019_16746_hotfix
# @DESCRIPTION:
# Checks for the CVE_2019_16746 patch
function fetch_cve_2019_16746_hotfix() {
	if grep -F -e "validate_beacon_head" "${S}/net/wireless/nl80211.c" >/dev/null ; then
		# already patched
		return
	fi
	local CVE_ID="CVE-2019-16746"
	if ! use cve_hotfix ; then
		_fetch_cve_boilerplate_msg
	fi
}

# @FUNCTION: fetch_cve_2019_14814_hotfix
# @DESCRIPTION:
# Checks for the CVE-2019-14814 patch
function fetch_cve_2019_14814_hotfix() {
	if grep -F -e "if (le16_to_cpu(ie->ie_length) + vs_ie->len + 2 >" "${S}/drivers/net/wireless/marvell/mwifiex/ie.c" >/dev/null ; then
		# already patched
		return
	fi
	local CVE_ID="CVE-2019-14814"
	if ! use cve_hotfix ; then
		_fetch_cve_boilerplate_msg
	fi
}

# @FUNCTION: fetch_cve_2019_14821_hotfix
# @DESCRIPTION:
# Checks for the CVE-2019-14821 patch
function fetch_cve_2019_14821_hotfix() {
	if grep -F -e "if (!coalesced_mmio_has_room(dev, insert) ||" "${S}/virt/kvm/coalesced_mmio.c" >/dev/null ; then
		# already patched
		return
	fi
	local CVE_ID="CVE-2019-14821"
	if ! use cve_hotfix ; then
		_fetch_cve_boilerplate_msg
	fi
}

# @FUNCTION: apply_cve_2019_16746_hotfix
# @DESCRIPTION:
# Applies the CVE_2019_16746 patch if it needs to
function apply_cve_2019_16746_hotfix() {
	local CVE_ID="CVE-2019-16746"
	local CVE_ID_="${CVE_ID//-/_}"
	local cve_severity="${CVE_ID_}_SEVERITY"
	local cve_fn="${CVE_ID_}_FN"
	if grep -F -e "validate_beacon_head" "${S}/net/wireless/nl80211.c" >/dev/null ; then
		einfo "${CVE_ID} is already patched."
		# already patched
		return
	fi
	if use cve_hotfix ; then
		if [ -e "${DISTDIR}/${!cve_fn}" ] ; then
			einfo "Resolving ${CVE_ID}.  ${!cve_fn} may break in different kernel versions."
			_dpatch "${PATCH_OPS}" "${DISTDIR}/${!cve_fn}"
		else
			ewarn "No ${CVE_ID} fixes applied.  This is a ${!cve_severity} risk vulnerability."
		fi
	else
		ewarn "No ${CVE_ID} fixes applied.  This is a ${!cve_severity} risk vulnerability."
	fi
}

# @FUNCTION: apply_cve_2019_14814_hotfix
# @DESCRIPTION:
# Applies the CVE_2019_14814 patch if it needs to
function apply_cve_2019_14814_hotfix() {
	local CVE_ID="CVE-2019-14814"
	local CVE_ID_="${CVE_ID//-/_}"
	local cve_severity="${CVE_ID_}_SEVERITY"
	local cve_fn="${CVE_ID_}_FN"
	if grep -F -e "if (le16_to_cpu(ie->ie_length) + vs_ie->len + 2 >" "${S}/drivers/net/wireless/marvell/mwifiex/ie.c" >/dev/null ; then
		einfo "${CVE_ID} is already patched."
		# already patched
		return
	fi
	if use cve_hotfix ; then
		if [ -e "${DISTDIR}/${!cve_fn}" ] ; then
			einfo "Resolving ${CVE_ID}.  ${!cve_fn} may break in different kernel versions."
			_dpatch "${PATCH_OPS}" "${DISTDIR}/${!cve_fn}"
		else
			ewarn "No ${CVE_ID} fixes applied.  This is a ${!cve_severity} risk vulnerability."
		fi
	else
		ewarn "No ${CVE_ID} fixes applied.  This is a ${!cve_severity} risk vulnerability."
	fi
}

# @FUNCTION: apply_cve_2019_14821_hotfix
# @DESCRIPTION:
# Applies the CVE_2019_14821 patch if it needs to
function apply_cve_2019_14821_hotfix() {
	local CVE_ID="CVE-2019-14821"
	local CVE_ID_="${CVE_ID//-/_}"
	local cve_severity="${CVE_ID_}_SEVERITY"
	local cve_fn="${CVE_ID_}_FN"
	if grep -F -e "if (!coalesced_mmio_has_room(dev, insert) ||" "${S}/virt/kvm/coalesced_mmio.c" >/dev/null ; then
		einfo "${CVE_ID} is already patched."
		# already patched
		return
	fi
	if use cve_hotfix ; then
		if [ -e "${DISTDIR}/${!cve_fn}" ] ; then
			einfo "Resolving ${CVE_ID}.  ${!cve_fn} may break in different kernel versions."
			_dpatch "${PATCH_OPS}" "${DISTDIR}/${!cve_fn}"
		else
			ewarn "No ${CVE_ID} fixes applied.  This is a ${!cve_severity} risk vulnerability."
		fi
	else
		ewarn "No ${CVE_ID} fixes applied.  This is a ${!cve_severity} risk vulnerability."
	fi
}

# @FUNCTION: fetch_cve_hotfixes
# @DESCRIPTION:
# Fetches all the CVE kernel patches
function fetch_cve_hotfixes() {
	if has cve_hotfix ${IUSE_EFFECTIVE} ; then
		fetch_cve_2019_16746_hotfix
		fetch_cve_2019_14814_hotfix
		fetch_cve_2019_14821_hotfix
	fi
}

# @FUNCTION: apply_cve_hotfixes
# @DESCRIPTION:
# Applies all the CVE kernel patches
function apply_cve_hotfixes() {
	if has cve_hotfix ${IUSE_EFFECTIVE} ; then
		einfo "Applying CVE hotfixes"
		apply_cve_2019_16746_hotfix
		apply_cve_2019_14814_hotfix
		apply_cve_2019_14821_hotfix
	fi
}
