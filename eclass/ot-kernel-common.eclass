#1234567890123456789012345678901234567890123456789012345678901234567890123456789
# Copyright 2019 Orson Teodoro
# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: ot-kernel-common.eclass
# @MAINTAINER:
# Orson Teodoro <orsonteodoro@hotmail.com>
# @AUTHOR:
# Orson Teodoro <orsonteodoro@hotmail.com>
# @SUPPORTED_EAPIS: 2 3 4 5 6
# @BLURB: Eclass for patching the kernel
# @DESCRIPTION:
# The ot-kernel-common eclass defines common patching steps for any linux
# kernel version.

# UKSM:
#   https://github.com/dolohow/uksm
# zen-tune:
#   https://github.com/torvalds/linux/compare/v5.3...zen-kernel:5.3/zen-tune
#   https://github.com/torvalds/linux/compare/v5.4...zen-kernel:5.4/zen-sauce commit 3e05ad861b9b2b61a1cbfd0d98951579eb3c85e0
# zen-kernel 5.3/misc:
#   https://github.com/torvalds/linux/compare/v5.3...zen-kernel:5.3/misc
#   https://github.com/torvalds/linux/compare/v5.4...zen-kernel:5.4/zen-sauce
#   https://github.com/torvalds/linux/compare/v5.5...zen-kernel:5.5/zen-sauce
# zen-kernel 5.3/futex-backports
#   https://github.com/torvalds/linux/compare/v5.3...zen-kernel:5.3/futex-backports
#   The original patch:
#     https://lwn.net/Articles/794969/
# zen-kernel 5.4/futex-backports
#   https://github.com/torvalds/linux/compare/v5.4...zen-kernel:5.4/futex-backports
# zen-kernel 5.5/futex-multiple-wait-v3
#   https://github.com/torvalds/linux/compare/v5.5...zen-kernel:5.5/futex-multiple-wait-v3
# O3 (Optimize Harder):
#   https://github.com/torvalds/linux/commit/e80b5baf29ce0fceb04ee4d05455c1e3a1871732
#   https://github.com/torvalds/linux/commit/360c6833e07cc9fdef5746f6bc45bdbc7212288d
# GraySky2 GCC Patches:
#   https://github.com/graysky2/kernel_gcc_patch
# MUQSS CPU Scheduler:
#   http://ck.kolivas.org/patches/muqss/4.0/4.14/
#   http://ck.kolivas.org/patches/5.0/5.3/5.3-ck1/
#   http://ck.kolivas.org/patches/5.0/5.4/5.4-ck1/
#   http://ck.kolivas.org/patches/5.0/5.5/5.5-ck1/
# PDS CPU Scheduler:
#   http://cchalpha.blogspot.com/search/label/PDS
# BMQ CPU Scheduler:
#   https://cchalpha.blogspot.com/search/label/BMQ
# genpatches:
#   https://dev.gentoo.org/~mpagano/genpatches/tarballs/
# BFQ updates:
#   https://github.com/torvalds/linux/compare/v5.3...zen-kernel:5.3/bfq-backports
#   https://github.com/torvalds/linux/compare/v5.4...zen-kernel:5.4/bfq-backports
#   https://github.com/torvalds/linux/compare/v5.5...zen-kernel:5.5/bfq-backports
# TRESOR:
#   http://www1.informatik.uni-erlangen.de/tresor

# TRESOR is maybe broken.  It requires additional coding for skcipher.
# Use the 4.9 series if you want to use TRESOR.
# See aesni-intel_glue.c chacha20_glue.c tresor_glue.c aesni-intel_asm.S
#   aesni-intel_asm.S in arch/x86/crypto
# It needs to fill out the skcipher_alg structure and provide callbacks that
#   use the skcipher_request structure.
# CBC uses CRYPTO_ALG_TYPE_SKCIPHER
# ECB uses CRYPTO_ALG_TYPE_BLKCIPHER

# Parts that still need to be developed:
# TRESOR - incomplete API

case ${EAPI:-0} in
	7) die "this eclass doesn't support EAPI ${EAPI}" ;;
	*) ;;
esac

HOMEPAGE+="
          https://github.com/dolohow/uksm
          https://liquorix.net/
          https://github.com/graysky2/kernel_gcc_patch
	  http://ck-hack.blogspot.com/
          https://dev.gentoo.org/~mpagano/genpatches/
          http://algo.ing.unimo.it/people/paolo/disk_sched/
	  http://cchalpha.blogspot.com/search/label/PDS
	  https://cchalpha.blogspot.com/search/label/BMQ
	  http://www1.informatik.uni-erlangen.de/tresor
          "

inherit ot-kernel-cve

DEPEND+=" dev-util/patchutils
	  sys-apps/grep[pcre]"

# @FUNCTION: gen_kernel_seq
# @DESCRIPTION:
# Generates a sequence for point releases
# @CODE
# Parameters:
# $1 - x >= 2
# @CODE
gen_kernel_seq()
{
	# 1-2 2-3 3-4, $1 >= 2
	local s=""
	for ((to=2 ; to <= $1 ; to+=1)) ; do
		s=" $s $((${to}-1))-${to}"
	done
	echo $s
}

BMQ_FN="${BMQ_FN:=v${PATCH_BMQ_MAJOR_MINOR}_bmq${PATCH_BMQ_VER}.patch}"
BMQ_BASE_URL="https://gitlab.com/alfredchen/bmq/raw/master/${PATCH_BMQ_MAJOR_MINOR}/"
BMQ_SRC_URL="${BMQ_BASE_URL}${BMQ_FN}"

ZENTUNE_PROJ="zen-tune"
ZENTUNE_FN="${ZENTUNE_PROJ}-${PATCH_ZENTUNE_VER}.patch"
if [[ "${K_MAJOR_MINOR}" == "5.6" ]] ; then
ZENTUNE_URL_BASE="https://github.com/zen-kernel/zen-kernel/compare/"
ZENTUNE_DL_URL="${ZENTUNE_URL_BASE}${ZENTUNE_5_6_COMMIT}.patch"
ZENTUNE_DL_DEP_FN="ZEN-Add-CONFIG-to-rename-the-mq-deadline-scheduler-for-5_6.patch"
ZENTUNE_DL_DEP_URL="https://github.com/torvalds/linux/commit/857aae4518fe08752f004fe6c5c8295da63c5a7e.patch"
elif [[ "${K_MAJOR_MINOR}" == "5.5" ]] ; then
ZENTUNE_URL_BASE="https://github.com/zen-kernel/zen-kernel/compare/"
ZENTUNE_DL_URL="${ZENTUNE_URL_BASE}${ZENTUNE_5_5_COMMIT}.patch"
ZENTUNE_DL_DEP_FN="ZEN-Add-CONFIG-to-rename-the-mq-deadline-scheduler-for-5_5.patch"
ZENTUNE_DL_DEP_URL="https://github.com/torvalds/linux/commit/98d9dc7ec5a6df16372ccdd7e18e64bfc6d5990f.patch"
elif [[ "${K_MAJOR_MINOR}" == "5.4" ]] ; then
ZENTUNE_URL_BASE="https://github.com/torvalds/linux/commit/"
ZENTUNE_DL_URL="${ZENTUNE_URL_BASE}${ZENTUNE_5_4_COMMIT}.patch"
else
ZENTUNE_URL_BASE=\
"https://github.com/torvalds/linux/compare/v${PATCH_ZENTUNE_VER}...zen-kernel:${PATCH_ZENTUNE_VER}/"
ZENTUNE_DL_URL="${ZENTUNE_URL_BASE}${ZENTUNE_PROJ}.patch"
fi

ZENMISC_URL_BASE="https://github.com/torvalds/linux/commit/"

FUTEX_WAIT_MULTIPLE_BASE="https://github.com/torvalds/linux/compare/v${PATCH_ZENTUNE_VER}...zen-kernel:${PATCH_ZENTUNE_VER}/"
if [[ "${K_MAJOR_MINOR}" == "5.4" \
|| "${K_MAJOR_MINOR}" == "5.3" \
|| "${K_MAJOR_MINOR}" == "5.2" ]] ; then
FUTEX_WAIT_MULTIPLE_PROJ="futex-backports"
elif [[ "${K_MAJOR_MINOR}" == "5.5" \
	|| "${K_MAJOR_MINOR}" == "5.6" ]] ; then
FUTEX_WAIT_MULTIPLE_PROJ="futex-multiple-wait-v3"
fi
FUTEX_WAIT_MULTIPLE_FN="${FUTEX_WAIT_MULTIPLE_PROJ}-${K_MAJOR_MINOR}.patch"
FUTEX_WAIT_MULTIPLE_DL_URL="${FUTEX_WAIT_MULTIPLE_BASE}${FUTEX_WAIT_MULTIPLE_PROJ}.patch"

UKSM_BASE="https://raw.githubusercontent.com/dolohow/uksm/master/v${PATCH_UKSM_MVER}.x/"
UKSM_FN="uksm-${PATCH_UKSM_VER}.patch"
UKSM_SRC_URL="${UKSM_BASE}${UKSM_FN}"

O3_SRC_URL="https://github.com/torvalds/linux/commit/"
O3_CO_FN="O3-config-option-${PATCH_O3_CO_COMMIT}.patch"
O3_RO_FN="O3-fix-readoverflow-${PATCH_O3_RO_COMMIT}.patch"
O3_CO_DL_FN="${PATCH_O3_CO_COMMIT}.patch"
O3_RO_DL_FN="${PATCH_O3_RO_COMMIT}.patch"
O3_CO_SRC_URL="${O3_SRC_URL}${O3_CO_DL_FN} -> ${O3_CO_FN}"
O3_RO_SRC_URL="${O3_SRC_URL}${O3_RO_DL_FN} -> ${O3_RO_FN}"

O3_ALLOW_FN="O3-allow-unrestricted-${PATCH_ALLOW_O3_COMMIT}.patch"
O3_ALLOW_SRC_URL="${O3_SRC_URL}${PATCH_ALLOW_O3_COMMIT}.patch -> ${O3_ALLOW_FN}"

GRAYSKY_DL_4_9_FN=\
"${GRAYSKY_DL_4_9_FN:=enable_additional_cpu_optimizations_for_gcc_v4.9%2B_kernel_v4.13%2B.patch}"
GRAYSKY_DL_8_1_FN=\
"enable_additional_cpu_optimizations_for_gcc_v8.1%2B_kernel_v4.13%2B.patch"
if ver_test ${K_MAJOR_MINOR} -ge 5.5 ; then
GRAYSKY_DL_9_1_FN=\
"enable_additional_cpu_optimizations_for_gcc_v9.1%2B_kernel_v5.5%2B.patch"
elif ver_test ${K_MAJOR_MINOR} -ge 4.13 ; then
GRAYSKY_DL_9_1_FN=\
"enable_additional_cpu_optimizations_for_gcc_v9.1%2B_kernel_v4.13%2B.patch"
fi
GRAYSKY_URL_BASE=\
"https://raw.githubusercontent.com/graysky2/kernel_gcc_patch/master/"
GRAYSKY_SRC_4_9_URL="${GRAYSKY_URL_BASE}${GRAYSKY_DL_4_9_FN}"
GRAYSKY_SRC_8_1_URL="${GRAYSKY_URL_BASE}${GRAYSKY_DL_8_1_FN}"
GRAYSKY_SRC_9_1_URL="${GRAYSKY_URL_BASE}${GRAYSKY_DL_9_1_FN}"

GENPATCHES_URL_BASE="https://dev.gentoo.org/~mpagano/genpatches/tarballs/"
GENPATCHES_BASE_FN="genpatches-${PATCH_GP_MAJOR_MINOR_REVISION}.base.tar.xz"
GENPATCHES_EXPERIMENTAL_FN="genpatches-${PATCH_GP_MAJOR_MINOR_REVISION}.experimental.tar.xz"
GENPATCHES_EXTRAS_FN="genpatches-${PATCH_GP_MAJOR_MINOR_REVISION}.extras.tar.xz"
GENPATCHES_BASE_SRC_URL="${GENPATCHES_URL_BASE}${GENPATCHES_BASE_FN}"
GENPATCHES_EXPERIMENTAL_SRC_URL="${GENPATCHES_URL_BASE}${GENPATCHES_EXPERIMENTAL_FN}"
GENPATCHES_EXTRAS_SRC_URL="${GENPATCHES_URL_BASE}${GENPATCHES_EXTRAS_FN}"

TRESOR_AESNI_FN="tresor-patch-${PATCH_TRESOR_VER}_aesni"
TRESOR_I686_FN="tresor-patch-${PATCH_TRESOR_VER}_i686"
TRESOR_SYSFS_FN="tresor_sysfs.c"
TRESOR_README_FN="tresor-readme.html"
TRESOR_AESNI_DL_URL="http://www1.informatik.uni-erlangen.de/filepool/projects/tresor/${TRESOR_AESNI_FN}"
TRESOR_I686_DL_URL="http://www1.informatik.uni-erlangen.de/filepool/projects/tresor/${TRESOR_I686_FN}"
TRESOR_SYSFS_DL_URL="http://www1.informatik.uni-erlangen.de/filepool/projects/tresor/${TRESOR_SYSFS_FN}"
TRESOR_README_DL_URL="https://www1.informatik.uni-erlangen.de/tresor?q=content/readme"
TRESOR_SRC_URL="${TRESOR_README_DL_URL} -> ${TRESOR_README_FN}"

KERNEL_INC_BASEURL="https://cdn.kernel.org/pub/linux/kernel/v${K_PATCH_XV}/incr/"
KERNEL_PATCH_0_TO_1_URL="https://cdn.kernel.org/pub/linux/kernel/v${K_PATCH_XV}/patch-${K_MAJOR_MINOR}.1.xz"

LINUX_REPO_URL="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"

if ver_test ${PV} -eq ${K_MAJOR_MINOR} ; then
KERNEL_NO_POINT_RELEASE="1"
elif ver_test ${PV} -eq ${K_MAJOR_MINOR}.0 ; then
KERNEL_0_TO_1_ONLY="1"
fi

if [[ -n "${KERNEL_NO_POINT_RELEASE}" && "${KERNEL_NO_POINT_RELEASE}" == "1" ]] ; then
	KERNEL_PATCH_URLS=()
elif [[ -n "${KERNEL_0_TO_1_ONLY}" && "${KERNEL_0_TO_1_ONLY}" == "1" ]] ; then
	KERNEL_PATCH_URLS=(${KERNEL_PATCH_0_TO_1_URL})
	KERNEL_PATCH_FNS_EXT=(patch-${K_MAJOR_MINOR}.1.xz)
	KERNEL_PATCH_FNS_NOEXT=(patch-${K_MAJOR_MINOR}.1)
else
	KERNEL_PATCH_TO_FROM=($(gen_kernel_seq $(ver_cut 3 ${PV})))
	KERNEL_PATCH_FNS_EXT=(${KERNEL_PATCH_TO_FROM[@]/%/.xz})
	KERNEL_PATCH_FNS_EXT=\
(${KERNEL_PATCH_FNS_EXT[@]/#/patch-${K_MAJOR_MINOR}.})
	KERNEL_PATCH_FNS_NOEXT=\
(${KERNEL_PATCH_TO_FROM[@]/#/patch-${K_MAJOR_MINOR}.})
	KERNEL_PATCH_URLS=\
(${KERNEL_PATCH_0_TO_1_URL} ${KERNEL_PATCH_FNS_EXT[@]/#/${KERNEL_INC_BASEURL}})
	KERNEL_PATCH_FNS_EXT=\
(patch-${K_MAJOR_MINOR}.1.xz ${KERNEL_PATCH_FNS_EXT[@]/#/patch-${K_MAJOR_MINOR}.})
	KERNEL_PATCH_FNS_NOEXT=\
(patch-${K_MAJOR_MINOR}.1 ${KERNEL_PATCH_TO_FROM[@]/#/patch-${K_MAJOR_MINOR}.})
fi

PDS_URL_BASE=\
"https://gitlab.com/alfredchen/PDS-mq/raw/master/${PATCH_PDS_MAJOR_MINOR}/"
PDS_FN="v${PATCH_PDS_MAJOR_MINOR}_pds${PATCH_PDS_VER}.patch"
PDS_SRC_URL="${PDS_URL_BASE}${PDS_FN}"

BFQ_FN="bfq-${PATCH_BFQ_VER}.patch"
BFQ_BRANCH="${BFQ_BRANCH:=bfq-backports}"
BFQ_DL_URL=\
"https://github.com/torvalds/linux/compare/v${PATCH_BFQ_VER}...zen-kernel:${PATCH_BFQ_VER}/${BFQ_BRANCH}.patch"
BFQ_SRC_URL="${BFQ_DL_URL} -> ${BFQ_FN}"

UNIPATCH_LIST=""

UNIPATCH_STRICTORDER="yes"

PATCH_OPS="-p1 -F 500"

# @FUNCTION: _dpatch
# @DESCRIPTION:
# Patch with die check.
# @CODE
# Parameters:
# $1 - patch options
# $2 - path of the patch
# @CODE
function _dpatch() {
	local patchops="$1"
	local path="$2"
	if [[ "${patchops}" =~ "-R" ]] ; then
		einfo "Reverting ${path}"
	else
		einfo "Applying ${path}"
	fi
	patch ${patchops} -i ${path} || die
}

# @FUNCTION: _tpatch
# @DESCRIPTION:
# Patch without die check, which may be followed by intervention corrective
# action, implied true as in normal operation.
# @CODE
# Parameters:
# $1 - patch options
# $2 - path of the patch
# @CODE
function _tpatch() {
	local patchops="$1"
	local path="$2"
	if [[ "${patchops}" =~ "-R" ]] ; then
		einfo "Reverting ${path}"
	else
		einfo "Applying ${path}"
	fi
	patch ${patchops} -i ${path} || true
}

# @FUNCTION: apply_uksm
# @DESCRIPTION:
# Apply the UKSM patches.
#
# ot-kernel-common_uksm_fixes - callback to fix the patch
#
function apply_uksm() {
	_tpatch "${PATCH_OPS} -N" "${DISTDIR}/${UKSM_FN}"

	if declare -f ot-kernel-common_uksm_fixes > /dev/null ; then
		ot-kernel-common_uksm_fixes
	fi
}

# @FUNCTION: apply_bfq
# @DESCRIPTION:
# Apply the BFQ patches.
function apply_bfq() {
	_dpatch "${PATCH_OPS} -N" "${T}/${BFQ_FN}"
}

# @FUNCTION: apply_zentune
# @DESCRIPTION:
# Apply the ZenTune patches.
function apply_zentune() {
	if ver_test "${K_MAJOR_MINOR}" -eq 5.5 ; then
		_dpatch "${PATCH_OPS} -N" "${T}/${ZENTUNE_DL_DEP_FN}"
	fi
	_dpatch "${PATCH_OPS} -N" "${T}/${ZENTUNE_FN}"
}

function apply_zentune_revert_5_5() {
	einfo "Applying zentune revert(s) for ${K_MAJOR_MINOR}"
	_dpatch "${PATCH_OPS} -N" "${DISTDIR}/${ZENTUNE_5_5_ADDENDIUM_DEST_FN}"
}

# @FUNCTION: apply_zenmisc
# @DESCRIPTION:
# Applies whitelisted Zen misc patches.
function apply_zenmisc() {
	local ZM="ZENMISC_WHITELIST_${K_MAJOR_MINOR/./_}"
	for c in ${!ZM} ; do
		if ver_test -ge 5.4 ; then
			if [[ "${c}" == "${PATCH_ALLOW_O3_COMMIT}" \
				|| "${c}" == "${PATCH_GRAYSKY2_GCC_COMMIT}" \
				|| "${c}" == "${ZENTUNE_5_4_COMMIT}" ]]
			then
				continue
			fi
		else
			if [[ "${c}" == "${PATCH_O3_CO_COMMIT}" \
				|| "${c}" == "${PATCH_O3_RO_COMMIT}" \
				|| "${c}" == "${PATCH_GRAYSKY2_GCC_COMMIT}" ]]
			then
				continue
			fi
		fi
		_tpatch "${PATCH_OPS} -N" "${T}/zen-misc/${c}.patch"
	done
}

# @FUNCTION: apply_futex_wait_multiple
# @DESCRIPTION:
# Adds a new syscall operation FUTEX_WAIT_MULTIPLE to the futex
# syscall.  It may shave of <5% CPU usage.
function apply_futex_wait_multiple() {
	_dpatch "${PATCH_OPS} -N" "${T}/${FUTEX_WAIT_MULTIPLE_FN}"
}

# @FUNCTION: _filter_genpatches
# @DESCRIPTION:
# Applies a genpatch if not blacklisted.
#
# Define GENPATCHES_BLACKLIST as a space seperated string in make.conf or
# as a per-package env
#
# For example,
# GENPATCHES_BLACKLIST="2500 2600"
function _filter_genpatches() {
	# already applied
	# 5010-5012 GCC graysky2 patches
	P_GENPATCHES_BLACKLIST=" 5010 5011 5012"
	pushd "${d}" || die
		for f in $(ls -1) ; do
			#einfo "Processing ${f}"
			if [[ "${f}" =~ \.patch$ ]] ; then
				local l=$(echo "${f}" | cut -f1 -d"_")
				if (( ${l} < 1500 )) ; then
					# vanilla kernel inc patches
					# already applied
					continue
				fi
				local is_blacklist
				is_blacklist=0
				for x in ${P_GENPATCHES_BLACKLIST} ; do
					if [[ "${l}" == "${x}" ]] ; then
						is_blacklist=1
					fi
				done
				if [[ "${is_blacklist}" == "1" ]] ; then
					continue
				fi

				is_blacklist=0
				for x in ${GENPATCHES_BLACKLIST} ; do
					if [[ "${l}" == "${x}" ]] ; then
						is_blacklist=1
					fi
				done
				if [[ "${is_blacklist}" == "1" ]] ; then
					einfo "Skipping genpatches ${l}"
					continue
				fi

				pushd "${S}" || die
					_tpatch "${PATCH_OPS} -N" "${d}/${f}"
				popd
			fi
		done
	popd
}

# @FUNCTION: apply_genpatch_base
# @DESCRIPTION:
# Apply the base genpatches patchset.
#
# ot-kernel-common_apply_genpatch_base_post - callback to apply individual
#   fixes
#
function apply_genpatch_base() {
	einfo "Applying the genpatch base"
	local d
	d="${T}/${GENPATCHES_BASE_FN%.tar.xz}"
	mkdir "$d"
	cd "$d" || die
	unpack "${GENPATCHES_BASE_FN}"

	sed -r -i -e "s|EXTRAVERSION = ${EXTRAVERSION}|EXTRAVERSION =|" \
		"${S}"/Makefile \
		|| die

	if [[ -n "${KERNEL_NO_POINT_RELEASE}" \
		&& "${KERNEL_NO_POINT_RELEASE}" == "1" ]] ; \
		then
		true
	else
		# genpatches places kernel incremental patches starting at 1000
		for a in ${KERNEL_PATCH_FNS_NOEXT[@]} ; do
			local f="${T}/${a}"
			cd "${T}" || die
			unpack "$a.xz"
			cd "${S}" || die
			patch --dry-run ${PATCH_OPS} -N "${f}" \
				| grep -F -e "FAILED at"
			if [[ "$?" == "1" ]] ; then
				# already patched or good
				_tpatch "${PATCH_OPS} -N" "${f}"
			else
				eerror "Failed ${l}"
				die
			fi
		done
	fi

	sed -r -i -e "s|EXTRAVERSION =|EXTRAVERSION = ${EXTRAVERSION}|" \
		"${S}"/Makefile \
		|| die

	cd "${S}" || die

	_filter_genpatches
}

# @FUNCTION: apply_genpatch_experimental
# @DESCRIPTION:
# Apply the experimental genpatches patchset.
#
# ot-kernel-common_apply_genpatch_experimental_patchset - callback to apply
#   individual patches
#
function apply_genpatch_experimental() {
	einfo "Applying genpatch experimental"

	local d
	d="${T}/${GENPATCHES_EXPERIMENTAL_FN%.tar.xz}"
	mkdir "$d"
	cd "$d" || die
	unpack "${GENPATCHES_EXPERIMENTAL_FN}"

	cd "${S}" || die

	_filter_genpatches
}

# @FUNCTION: apply_genpatch_extras
# @DESCRIPTION:
# Apply the extra genpatches patchset.
#
# ot-kernel-common_apply_genpatch_extras_patchset - callback to apply \
#   individual patches
#
function apply_genpatch_extras() {
	einfo "Applying genpatch extras"

	local d
	d="${T}/${GENPATCHES_EXTRAS_FN%.tar.xz}"
	mkdir "$d"
	cd "$d" || die
	unpack "${GENPATCHES_EXTRAS_FN}"

	cd "${S}" || die

	_filter_genpatches
}

# @FUNCTION: apply_o3
# @DESCRIPTION:
# Apply the GraySky2 O3 patchset.
#
# ot-kernel-common_apply_o3_fixes - callback for fix to O3 patches
#
function apply_o3() {
	cd "${S}" || die

	if ver_test "${K_MAJOR_MINOR}" -ge 5.4 ; then
		einfo "Allow O3 unrestricted"
		_tpatch "${PATCH_OPS}" "${DISTDIR}/${O3_ALLOW_FN}"
	elif ver_test "${K_MAJOR_MINOR}" -lt 5.4 ; then
		# fix patch
		sed -r -e "s|-1028,6 +1028,13|-1076,6 +1076,13|" \
			"${DISTDIR}"/${O3_CO_FN} \
			> "${T}"/${O3_CO_FN} || die

		einfo "Applying O3"
		ewarn \
"Some patches have hunk(s) failed but still good or may be fixed ASAP."

		einfo "Applying ${O3_CO_FN}"
		_tpatch "${PATCH_OPS}" "${T}/${O3_CO_FN}"

		einfo "Applying ${O3_RO_FN}"
		mkdir -p drivers/gpu/drm/amd/display/dc/basics/
		# trick patch for unattended patching
		touch drivers/gpu/drm/amd/display/dc/basics/logger.c
		_tpatch "-p1 -N" "${DISTDIR}/${O3_RO_FN}"
	fi

	if declare -f ot-kernel-common_apply_o3_fixes > /dev/null ; then
		ot-kernel-common_apply_o3_fixes
	fi
}

# @FUNCTION: apply_pds
# @DESCRIPTION:
# Apply the PDS CPU scheduler patchset.
function apply_pds() {
	cd "${S}" || die
	einfo "Applying pds"
	_dpatch "${PATCH_OPS}" "${DISTDIR}/${PDS_FN}"
}

# @FUNCTION: apply_bmq
# @DESCRIPTION:
# Apply the BMQ CPU scheduler patchset.
#
# ot-kernel-common_apply_bmq_quickfixes - callback to apply quick fixes
#
function apply_bmq() {
	cd "${S}" || die
	einfo "Applying bmq"
	_dpatch "${PATCH_OPS}" "${DISTDIR}/${BMQ_FN}"

	if declare -f ot-kernel-common_apply_bmq_quickfixes > /dev/null ; then
		ot-kernel-common_apply_bmq_quickfixes
	fi
}

# @FUNCTION: apply_tresor
# @DESCRIPTION:
# Apply the TRESOR AES cold boot resistant patchset.
#
# ot-kernel-common_apply_tresor_fixes - callback to apply tresor fixes
#
function apply_tresor() {
	cd "${S}" || die
	einfo "Applying tresor"
	ewarn \
"Some patches have hunk(s) failed but still good or may be fixed ASAP."
	local platform
	if use tresor_aesni ; then
		platform="aesni"
	fi
	if use tresor_i686 || use tresor_x86_64 ; then
		platform="i686"
	fi

	_tpatch "${PATCH_OPS}" \
		"${DISTDIR}/tresor-patch-${PATCH_TRESOR_VER}_${platform}"
	if declare -f ot-kernel-common_apply_tresor_fixes > /dev/null ; then
		ot-kernel-common_apply_tresor_fixes
	fi
}

# @FUNCTION: fetch_bfq
# @DESCRIPTION:
# Fetches the BFQ patchset.
function fetch_bfq() {
	einfo "Fetching the BFQ patch from a live source..."
	wget -O "${T}/${BFQ_FN}" "${BFQ_DL_URL}" || die
}

# @FUNCTION: fetch_zenmisc
# @DESCRIPTION:
# Fetches select commits from zen-misc @
# https://github.com/torvalds/linux/compare/v5.3...zen-kernel:5.3/misc
#
# Commits must be in correct topological order (i.e. A->B->C->D), where
# A is first merge, B is second, C is third, D is fourth and final merge if
# same commit and has the same timestamp.  If has different timestamp
# older-left from newer-right.
#
# The site above you append them from bottom to up in ZENMISC_WHITELIST_5_3
# where 5_3 is the kernel MAJOR_MINOR which is stored in /etc/make.conf
# or as a per-package environmental variable.
#
# It's your responsibility to vet each commit yourself.
# Adding any code from any source may introduce additional attack vectors, legal
# problems, memory leaks, etc.
#
# For example,
# ZENMISC_WHITELIST_5_3="214d031dbeef940efe1dbba274caf5ccc4ff2774 83d7f482c60b6dfda030325394ec07baac7f5a30"
#
# 214d0  ZEN: Add Thinkpad SMAPI driver
# 83d7f  x86/umip: Add emulation (spoofing) for UMIP covered instructions in
#          64-bit processes as well
function fetch_zenmisc() {
	einfo "Fetching select zen-misc commits from a live source..."
	mkdir -p "${T}/zen-misc" || die
	local ZM="ZENMISC_WHITELIST_${K_MAJOR_MINOR/./_}"
	for c in ${!ZM} ; do
		wget -O "${T}/zen-misc/${c}.patch" \
		"${ZENMISC_URL_BASE}${c}.patch" || die
	done
}

# @FUNCTION: fetch_zentune
# @DESCRIPTION:
# Fetches the zentune patchset.
function fetch_zentune() {
	einfo "Fetching the zen-tune patch from a live source..."
	if ver_test "${K_MAJOR_MINOR}" -eq 5.5 ; then
		wget -O "${T}/${ZENTUNE_DL_DEP_FN}" "${ZENTUNE_DL_DEP_URL}" || die
	fi
	wget -O "${T}/${ZENTUNE_FN}" "${ZENTUNE_DL_URL}" || die
}

# @FUNCTION: fetch_futex_wait_multiple
# @DESCRIPTION:
# Fetches the FUTEX_WAIT_MULTIPLE patchset.
function fetch_futex_wait_multiple() {
	einfo "Fetching the futex-wait-multiple patch from a live source..."
	wget -O "${T}/${FUTEX_WAIT_MULTIPLE_FN}" "${FUTEX_WAIT_MULTIPLE_DL_URL}" || die
}

# @FUNCTION: fetch_linux_sources
# @DESCRIPTION:
# Fetches a local copy of the linux kernel repo.
function fetch_linux_sources() {
	einfo "Fetching the vanilla Linux kernel sources.  It may take hours."
	local distdir="${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}"
	cd "${DISTDIR}" || die
	d="${distdir}/ot-sources-src/linux"
	b="${distdir}/ot-sources-src"
	addwrite "${b}"
	cd "${b}" || die

	if [[ -d "${d}" ]] ; then
		pushd "${d}" || die
		if ! ( git remote -v | grep -F -e "${LINUX_REPO_URL}" ) \
			> /dev/null ; \
		then
			einfo "Removing ${d}"
			rm -rf "${d}" || die
		fi
		popd
	fi

	addwrite "${b}"

	if [[ ! -d "${d}" ]] ; then
		mkdir -p "${d}" || die
		einfo "Cloning the vanilla Linux kernel project"
		git clone "${LINUX_REPO_URL}" "${d}"
		cd "${d}" || die
		git checkout master
		git checkout -b v${PV} tags/v${PV}
	else
		local G=$(find "${d}" -group "root")
		if (( ${#G} > 0 )) ; then
			die \
"You must manually \`chown -R portage:portage ${d}\`.  Re-emerge again."
		fi
		einfo "Updating the vanilla Linux kernel project"
		cd "${d}" || die
		git clean -fdx
		git reset --hard master
		git reset --hard origin/master
		git checkout master
		git pull
		git branch -D v${PV}
		git checkout -b v${PV} tags/v${PV}
		git pull
	fi
	cd "${d}" || die
}

# @FUNCTION: ot-kernel-common_src_unpack
# @DESCRIPTION:
# Applies patch sets in order.  It calls kernel-2_src_unpack.
function ot-kernel-common_src_unpack() {
	#if use zentune ; then
	#	UNIPATCH_LIST+=" ${DISTDIR}/${ZENTUNE_FN}"
	#fi
	#if use uksm ; then
	#	UNIPATCH_LIST+=" ${DISTDIR}/${UKSM_FN}"
	#fi
	if use muqss ; then
		UNIPATCH_LIST+=" ${DISTDIR}/${CK_FN}"
	fi
	if use graysky2 ; then
		if $(ver_test $(gcc-version) -ge 9.1) \
			&& test -f "${DISTDIR}/${GRAYSKY_DL_9_1_FN}" ; \
		then
			einfo "GCC patch is 9.1"
			UNIPATCH_LIST+=" ${DISTDIR}/${GRAYSKY_DL_9_1_FN}"
		elif $(ver_test $(gcc-version) -ge 8.1) \
			&& test -f "${DISTDIR}/${GRAYSKY_DL_8_1_FN}" ; \
		then
			einfo "GCC patch is 8.1"
			UNIPATCH_LIST+=" ${DISTDIR}/${GRAYSKY_DL_8_1_FN}"
		elif test -f "${DISTDIR}/${GRAYSKY_DL_4_9_FN}" ; then
			einfo "GCC patch is 4.9"
			UNIPATCH_LIST+=" ${DISTDIR}/${GRAYSKY_DL_4_9_FN}"
		else
			die "Cannot find graysky2's GCC patch."
		fi
	fi
	#if use bfq ; then
	#	UNIPATCH_LIST+=" ${DISTDIR}/${BFQ_FN}"
	#fi

	kernel-2_src_unpack

	cd "${S}" || die

	if has zentune ${IUSE_EFFECTIVE} ; then
		if use zentune ; then
			fetch_zentune
			apply_zentune
			if ver_test ${K_MAJOR_MINOR} -eq 5.5 ; then
				apply_zentune_revert_5_5
			fi
		fi
	fi

	if has zenmisc ${IUSE_EFFECTIVE} ; then
		if use zenmisc ; then
			fetch_zenmisc
			apply_zenmisc
		fi
	fi

	if has futex-wait-multiple ${IUSE_EFFECTIVE} ; then
		if use futex-wait-multiple ; then
			fetch_futex_wait_multiple
			apply_futex_wait_multiple
		fi
	fi

	if use uksm ; then
		apply_uksm
	fi

	if has bfq ${IUSE_EFFECTIVE} ; then
		if use bfq ; then
			fetch_bfq
			apply_bfq
		fi
	fi

	if use muqss ; then
		#_dpatch "${PATCH_OPS}" "${FILESDIR}/MuQSS-4.18-missing-se-member.patch"
		_dpatch "${PATCH_OPS}" "${FILESDIR}/muqss-dont-attach-ckversion.patch"
	fi

	if has pds ${IUSE_EFFECTIVE} ; then
		if use pds ; then
			apply_pds
		fi
	fi

	if has bmq ${IUSE_EFFECTIVE} ; then
		if use bmq ; then
			apply_bmq
		fi
	fi

	apply_genpatch_base
	apply_genpatch_extras
	apply_genpatch_experimental

	# should be done after all the kernel point releases contained in
	# apply_genpatch_base
	if has cve_hotfix ${IUSE_EFFECTIVE} ; then
		# may need to be put as the end of this subroutine
		if use cve_hotfix ; then
			fetch_tuxparoni
			unpack_tuxparoni
			fetch_cve_hotfixes
			get_cve_report
			test_cve_hotfixes
			apply_cve_hotfixes
		fi
	fi

	if has o3 ${IUSE_EFFECTIVE} ; then
		if use o3 ; then
			apply_o3
		fi
	fi

	if has tresor ${IUSE_EFFECTIVE} ; then
		if use tresor ; then
			apply_tresor
		fi
	fi


	#_dpatch "${PATCH_OPS}" "${FILESDIR}/linux-4.20-kconfig-ioscheds.patch"
}

# @FUNCTION: zenmisc_setup
# @DESCRIPTION:
# Checks the existance for the ZENMISC_WHITELIST_5_3 variable
function zenmisc_setup() {
	if use zenmisc ; then
		local ZM="ZENMISC_WHITELIST_${K_MAJOR_MINOR/./_}"
		if [[ -z "${!ZM}" ]] ; then
			local zenmisc_url
			if ver_test ${PV} -ge 5.4 ; then
				zenmisc_url=\
"https://github.com/torvalds/linux/compare/v${K_MAJOR_MINOR}...zen-kernel:${K_MAJOR_MINOR}/zen-sauce"
			else
				zenmisc_url=\
"https://github.com/torvalds/linux/compare/v${K_MAJOR_MINOR}...zen-kernel:${K_MAJOR_MINOR}/misc"
			fi

			eerror \
"You must define ZENMISC_WHITELIST_${K_MAJOR_MINOR} in /etc/make.conf\n\
or as a per-package env containing commits to accepted from\n\
  ${zenmisc_url}\n\
\n\
For example:\n\
\n\
  ZENMISC_WHITELIST_${K_MAJOR_MINOR/./_}=\"214d031dbeef940efe1dbba274caf5ccc4ff2774 83d7f482c60b6dfda030325394ec07baac7f5a30\"\n\
\n\
This must be in chronological and topological order (if the timestamp is the\n\
same) from oldest-left to newest-right."
			die
		fi
	fi
}

# @FUNCTION: _check_network_sandbox
# @DESCRIPTION:
# Check if sandbox is more lax when downloading in unpack phase
function _check_network_sandbox() {
	# justifications
	# bfq - no way to compare against "branch with commit"
	#   (i.e. v${K_MAJOR_MINOR}...zen-kernel:${K_MAJOR_MINOR}/misc/${c})
	# zenmisc - random choice of commits by user, mimimize
	#   downloading unnecessary commits, less manifest
	#   entries
	# zentune - no way to version as explained in bfq
	if has network-sandbox $FEATURES ; then
		die \
"FEATURES=\"-network-sandbox\" must be added per-package env to be able to use\n\
live patches."
	fi
}

# @FUNCTION: ot-kernel-common_pkg_setup_cb
# @DESCRIPTION:
# Perform checks, warnings, and initialization before emerging
function ot-kernel-common_pkg_setup() {
	if has zenmisc ${IUSE_EFFECTIVE} ; then
		if use zenmisc ; then
			_check_network_sandbox
		fi
	fi
	if has zentune ${IUSE_EFFECTIVE} ; then
		if use zentune ; then
			_check_network_sandbox
		fi
	fi
	if has bfq ${IUSE_EFFECTIVE} ; then
		if use bfq ; then
			_check_network_sandbox
		fi
	fi
	if has futex-wait-multiple ${IUSE_EFFECTIVE} ; then
		if use bfq ; then
			_check_network_sandbox
		fi
	fi

	if declare -f ot-kernel-common_pkg_setup_cb > /dev/null ; then
		ot-kernel-common_pkg_setup_cb
	fi
	if has zenmisc ${IUSE_EFFECTIVE} ; then
		zenmisc_setup
	fi
	if has cve_hotfix ${IUSE_EFFECTIVE} ; then
		if use cve_hotfix ; then
			_check_network_sandbox
		fi
	fi
}

# @FUNCTION: ot-kernel-common_pkg_pretend_cb
# @DESCRIPTION:
# Perform checks and warnings before emerging
function ot-kernel-common_pkg_pretend() {
	if declare -f ot-kernel-common_pkg_pretend_cb > /dev/null ; then
		ot-kernel-common_pkg_pretend_cb
	fi
}

# @FUNCTION: ot-kernel-common_src_compile
# @DESCRIPTION:
# Compiles the userland programs especially the post-boot TRESOR AES post boot
# program.
function ot-kernel-common_src_compile() {
	if has tresor_sysfs ${IUSE_EFFECTIVE} ; then
		if use tresor_sysfs ; then
			cp -a "${DISTDIR}/tresor_sysfs.c" "${T}"
			cd "${T}" || die
			einfo "$(tc-getCC) ${CFLAGS}"
			$(tc-getCC) ${CFLAGS} tresor_sysfs.c -o tresor_sysfs || die
		fi
	fi
}

# @FUNCTION: ot-kernel-common_src_install
# @DESCRIPTION:
# Removes patch cruft.
function ot-kernel-common_src_install() {
	find "${S}" -name "*.orig" -print0 -o -name "*.rej" -print0 \
		| xargs -0 rm

	if has tresor ${IUSE_EFFECTIVE} ; then
		if use tresor ; then
			docinto /usr/share/${PF}
			dodoc "${DISTDIR}/tresor-readme.html"
		fi
	fi

}

# @FUNCTION: ot-kernel-common_pkg_postinst
# @DESCRIPTION:
# Present warnings and avoid collision checks.
#
# ot-kernel-common_pkg_postinst_cb - callback if any to handle after emerge phase
#
function ot-kernel-common_pkg_postinst() {
	if use disable_debug ; then
		einfo \
"The disable debug scripts have been placed in your /usr/src folder.\n"\
"They disable debug paths, logging, output for a performance gain.\n"\
"You should run it like \`/usr/src/disable_debug x86_64 /usr/src/.config\`\n"
		cp "${FILESDIR}/_disable_debug_v${DISABLE_DEBUG_V}" \
			"${EROOT}/usr/src/_disable_debug" || die
		cp "${FILESDIR}/disable_debug_v${DISABLE_DEBUG_V}" \
			"${EROOT}/usr/src/disable_debug" || die
		chmod 700 "${EROOT}"/usr/src/_disable_debug || die
		chmod 700 "${EROOT}"/usr/src/disable_debug || die
	fi

	if has tresor_sysfs ${IUSE_EFFECTIVE} ; then
		if use tresor_sysfs ; then
			# prevent merge conflicts
			cd "${T}" || die
			mv tresor_sysfs "${EROOT}/usr/bin" || die
			chmod 700 "${EROOT}"/usr/bin/tresor_sysfs || die
			# same hash for 5.1 and 5.0.13 for tresor_sysfs
			einfo \
"/usr/bin/tresor_sysfs is provided to set your TRESOR key"
		fi
	fi

	if declare -f ot-kernel-common_pkg_postinst_cb > /dev/null ; then
		ot-kernel-common_pkg_postinst_cb
	fi

}
