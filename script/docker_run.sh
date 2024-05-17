#!/bin/bash
#
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
# Docker tools
# Script to run with ./Docker-builder.sh. Checks the 
# environment and configures the container before running
# both ISO-builder.sh and then IMG-builder.sh.

set -e

source ./config/BUILD.conf

# Create zone information files for tzdata
if [[ -n "${TZ}" ]]; then
    /usr/bin/echo "Creating zone information files: ${TZ}"
    /usr/bin/ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
    /usr/bin/echo "${TZ}" > /etc/timezone
else
    /usr/bin/echo '$TZ is NOT SET!'
    exit
fi

# Create a ./log directory if it does not exist
if [[ ! -d ./log ]]; then
    /usr/bin/echo 'Generating log directory...'
    /usr/bin/mkdir -v ./log
fi

/usr/bin/echo 'Updating build packages...'
# Prepare the container by updating the package lists
/usr/bin/apt-get update | /usr/bin/tee log/APT.log

/usr/bin/echo 'Installing packages on build machine, this may take a while...'
# Install all dependencies
/usr/bin/apt-get install -y $(/usr/bin/cat /project/config/packages/BUILD) | /usr/bin/tee -a log/APT.log

# Generate the ISO-artifact
./ISO-builder.sh | /usr/bin/tee log/ISO-builder.log

# Generate the IMG-artifact
./IMG-builder.sh | /usr/bin/tee log/IMG-builder.log

# Finish
exit
