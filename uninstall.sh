#!/usr/bin/env bash
#
# Uninstall Wireshark based on the rough guidance provided in the
# "Read me first.rtf" distributed with Wireshark
#
# From "Read me first.rtf"
# How do I uninstall?
#
# 1.  Remove /Applications/Wireshark.app
# 2.  Remove /Library/Application Support/Wireshark
# 3.  Remove the wrapper scripts from /usr/local/bin
# 4.  Unload the org.wireshark.ChmodBPF.plist launchd job
# 5.  Remove /Library/LaunchDaemons/org.wireshark.ChmodBPF.plist
# 6.  Remove the access_bpf group.


export PATH='/usr/bin:/usr/sbin:/bin:/sbin'

# Packages installed by Wireshark
packages=(
  "org.wireshark.ChmodBPF.pkg"
  "org.wireshark.cli.pkg"
  "org.wireshark.Wireshark.pkg"
  )

# Application bundle
application_bundle='/Applications/Wireshark.app'

# launchd job
launchd_job='/Library/LaunchDaemons/org.wireshark.ChmodBPF.plist'

# Appplication support assets
application_support='/Library/Application Support/Wireshark'

assets=(
  ${application_bundle}
  ${application_support}
  ${launchd_job}
  )

#----------------------------------------------------------------------
# Functions
#----------------------------------------------------------------------

# Prints an error message to stderr
#
# @param1 [string] $@ Error string
function err() {
  echo "[Error]: $*" >&2
}

# Prints a confirmation dialogue
#
# @param1 [string] $1 Prompt
confirm() {
  # call with a prompt string or use a default
  read -r -p "${1:-Are you sure? [y/N]} " response
  case ${response} in
    [yY][eE][sS]|[yY])
      true
      ;;
    *)
      false
      ;;
  esac
}

# Gets the volume the named package was installed on
#
# @param1 [string] $1 Package name
get_pkg_vol() {
  local vol=$(pkgutil --pkg-info "${1}" | awk '/volume:/{print $2}')
  echo "${vol}"
}

# Gets the location under the volume the named package was installed on
#
# @param1 [string] $1 package name
get_pkg_loc() {
  local loc=$(pkgutil --pkg-info "${1}" | awk '/location:/{print $2}')
  echo "${loc}"
}

# Delete all files on receipt for named package
#
# @param1 [string] $1 package name
forget_pkg() {
  pkgutil --forget "${1}" > /dev/null 2>&1
}

unload_launchd_job() {
  return $(launchctl unload ${launchd_job})
}

# Removes (recursively if needed) as file
#
# @param1 [string] $1 filename
remove_file() {
  if [[ -e ${1} ]]; then
    rm -rf "${1}"
  fi
}

# Manually remove the Wireshark files not in pacakge receipts
#
# @param1 [string] $1 package name
remove_package() {
  # The CLI package doesn't list all of the files it creates properly in
  # its receipt, so they must be manually removed - other packages register
  # thier contents correctly
  if [ "${1}" = 'org.wireshark.cli.pkg' ]; then
    local path="$(get_pkg_vol "${1}")$(get_pkg_loc "${1}")"

    local bins=(
      'capinfos'
      'dftest'
      'dumpcap'
      'editcap'
      'mergecap'
      'randpkt'
      'rawshark'
      'text2pcap'
      'tshark'
      'wireshark'
      )

    local bin
    for bin in "${bins[@]}"; do
      remove_file "${path}/${bin}"
    done
  fi
  forget_pkg "${1}"
}

# Restore permissions on bpf devices
restore_bpf_dev()
{
  chgrp wheel /dev/bpf*
  chmod g-rw /dev/bpf*
}

# Remove the bpf groups
remove_access_bpf_group()
{
  local group='access_bpf'
  if dscl . -list /Groups/${group} > /dev/null 2>&1; then
    dscl . -delete /Groups/${group}
  else
    err "Group ${group} was not found"
  fi
}

#----------------------------------------------------------------------
# Script
#----------------------------------------------------------------------
# Main script body

# Verify script is being run as root
if [[ ${EUID} -ne 0 ]]; then
  err 'Please run this script as root'
  exit 1
fi

# Confirm uninstall
if ! confirm 'Uninstall Wireshark? [y/N] '; then
 echo  'Aborting uninstall.' >&2
 exit 1
fi

# Restore launchd state
unload_launchd_job

# Remove the named packages and artifacts
for pkg in "${packages[@]}"; do
  if pkgutil --pkgs | grep -E "^${pkg}\$" > /dev/null 2>&1; then
    remove_package "${pkg}"
  else
    err "The package ${pkg} was not found"
  fi
done

# Remove assest not bound to packages
for asset in "${assets[@]}"; do
  remove_file "${asset}"
done

# Remove access_bpf group and resture bpf device permissions
restore_bpf_dev
remove_access_bpf_group
