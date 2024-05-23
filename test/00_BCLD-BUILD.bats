#
# Copyright © 2024 Quintor B.V.
#
# BCLD is gelicentieerd onder de EUPL, versie 1.2 of
# – zodra ze zullen worden goedgekeurd door de Europese Commissie -
# latere versies van de EUPL (de "Licentie");
# U mag BCLD alleen gebruiken in overeenstemming met de licentie.
# U kunt een kopie van de licentie verkrijgen op:
#
# https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
#
# Tenzij vereist door de toepasselijke wetgeving of overeengekomen in
# schrijven, wordt software onder deze licentie gedistribueerd
# gedistribueerd op een "AS IS"-basis,
# ZONDER ENIGE GARANTIES OF VOORWAARDEN, zowel
# expliciet als impliciet.
# Zie de licentie voor de specifieke taal die van toepassing is
# en de beperkingen van de licentie.
#
#
# Copyright © 2024 Quintor B.V.
#
# BCLD is licensed under the EUPL, Version 1.2 or 
# – as soon they will be approved by the European Commission -
# subsequent versions of the EUPL (the "Licence");
# You may not use BCLD except in compliance with the Licence.
# You may obtain a copy of the License at:
#
# https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
#
# Unless required by applicable law or agreed to in
# writing, software distributed under the License is
# distributed on an "AS IS" basis,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied.
# See the License for the specific language governing
# permissions and limitations under the License.
# 
#
# Per-build Bash tests
# Build a TEST image and check if all TAGs are being marked.
# Check if Grub was installed on the image.
#
# Setup
setup() {
	load 'common-setup'
    _common_setup
    [ ! -f ${BATS_PARENT_TMPNAME}.skip ] || skip "(TEST FAILED)"
}

# Functions

## Function to check if a stage has been successful
tag_check() {
    refute_output --partial "${1} FAILED!!!"
	assert_output --partial "${1} COMPLETE!"
}

## Function to check on generated artifacts
art_check() {
	if [[ ! -f "${1}" ]]; then
		/usr/bin/echo "FAILED: ${1} is missing!"
	fi
}

## Function to check size on generated ISO file
iso_size () {
	ISO_SIZE="$(/usr/bin/du ./artifacts/bcld.iso | /usr/bin/awk ' { print $1 } ')"
	
	if [[ "${ISO_SIZE}" -lt 1000000 ]]; then
		/usr/bin/echo 'FAILED: ISO is smaller than 1GB! Something went wrong...'
	fi
}

## Function to check size on generated IMG file
img_size () {
	IMG_SIZE="$(/usr/bin/du ./artifacts/${BCLD_VERSION_FILE}.img | /usr/bin/awk ' { print $1 } ')"
	
	if [[ "${IMG_SIZE}" -lt 1000000 ]]; then
		/usr/bin/echo 'FAILED: IMG is smaller than 1GB! Something went wrong...'
	fi
}

# Tests
@test 'LicenseCheck' {
    run ./test/LICENSE-CHECK.sh
    
    assert_output --partial 'No missing licenses found'
    refute_output --partial 'Please supply all BCLD scripts of the appropriate EUPL license!'
}

@test 'ShellCheck' {
    run ./test/SHELL-CHECK.sh
    
    assert_output --partial 'ShellCheck ERRORS: 0'
    refute_output --partial 'Common ERRORS found!'
}

@test "Building ${BCLD_MODEL} ISO..." {
    /usr/bin/echo 'Building BCLD-ISO'
}

## Test if ISO Builder can execute
@test 'TagCheck' {
    run ./ISO-builder.sh
    tag_check 'ISO-INIT'
    tag_check 'ISO-PRECLEAN'
    tag_check 'ISO-PREP'
    tag_check 'ISO-BOOTSTRAP'
    tag_check 'ISO-PRECONF'
    tag_check 'ISO-SVCS'
    tag_check 'ISO-MOUNT'
    tag_check 'ISO-CHROOT'
    tag_check 'ISO-POSTCONF'
    tag_check 'ISO-CERT'
    tag_check 'ISO-TWEAKS'
    tag_check 'ISO-INITRAMFS'
    tag_check 'ISO-REPO'
    tag_check 'ISO-SQUASHFS'
    tag_check 'ISO-CLEANUP'
    tag_check 'ISO-GRUB'
    tag_check 'ISO-GEN'
    tag_check 'ISO-CLEAR'
    
    assert_output --partial 'ISO image created!'
}

## Test if ISO Builder can execute
@test 'GRUB Monitor' {
	run ./IMG-builder.sh
    refute_output --partial 'ISO-artifact missing!'
    assert_output --partial 'Installation finished. No error reported.'
    assert_output --partial "Added 'EFI'-label: EFI"
    assert_output --partial "Added 'BCLD-USB'-label: BCLD-USB"
    tag_check 'IMAGE-INIT'
    tag_check 'IMAGE-GRUB'
    tag_check 'IMAGE-BUILD'
}

## Test for checking if all artifacts are generated
@test 'ArtChecker' {
	run art_check ./artifacts/bcld.iso
	run art_check ./artifacts/{BCLD_VERSION_FILE}.img
	run art_check ./artifacts/bcld.cfg
	run art_check ./artifacts/info
	run art_check ./artifacts/PKGS_ALL
	run art_check ./image/ISO/EFI/BOOT
	run art_check ./image/ISO/EFI/BOOT/efi.img
	run art_check ./image/ISO/EFI/BOOT/grub.cfg
	run art_check ./image/ISO/EFI/BOOT/mmx64.efi
	run art_check ./image/ISO/isolinux/bios.img
	run art_check ./image/ISO/isolinux/grub.cfg
	run art_check ./image/ISO/isolinux/core.img
	run art_check ./test/BATS-REPORT.txt

	refute_output --partial 'FAILED'
}

## Test for checking if ISO is bigger than 1GB
@test 'ISOcheck' {
	run iso_size

	refute_output --partial 'FAILED'
}

## Test for checking if IMG is bigger than 1GB
@test 'IMGcheck' {
	run img_size

	refute_output --partial 'FAILED'
}

teardown() {
    [ -n "${BATS_TEST_COMPLETED}" ] || /usr/bin/touch ${BATS_PARENT_TMPNAME}.skip
}
