## General functions

# Script usage
function usage() {
  cat << EOF
${progname} ${progversion}

Usage: ${progname} <options>

Options:
 
  -n    Name of share (alphanumeric, dashes, dots and underscores only)
  -u    Specify the username (will be the same as the share name if not specified)
  -p    Specifies the password length
  -f    Do not prompt
  -i    Installs the main Apache conf file
  -h    Displays this help message

  * If no options are specified, a random share will be generated.

Example:

  # Generate a share called 'testshare' with username 'testuser' with a random password length of 16 characters:
  ${progname} -name testshare -u testuser -p 16

EOF
}

# Sets up required directories/files
function setup() {
  [ ! -d "${tmp_dir}" ] && mkdir "${tmp_dir}"
  [ ! -f "${conf_file}" ] && echoerr "Error: configuration file ${conf_file} not found. Please copy the included sample configuration file to ${conf_file}" && exit 1
  [ ! -d "${share_config_dir}" ] && mkdir -p "${share_config_dir}"
}

# Echo to debug/stderr
function echoerr() {
  echo "$@" >&2
}

# Log to log file
function log() {
  set -u && echo "$( date ) - $@" >> "${log_file}"
}

# Test if user is root
function is_root() {
  [ ${EUID} -eq 0 ] && return 0 || return 1
}

# Prints unix epoch time
function date_now() {
  echo "$( date +%s )"
}

# Checks a list an array of dependencies
function check_dependencies() {
  [ $# -eq 0 ] && echoerr "Error: no dependency defined." && exit 1
  local deps=( $@ )
  for dep in "${deps[@]}" ; do
    if ! which "${dep}" >/dev/null 2>&1 ; then
      echoerr "Error: dependency ${dep} not found in PATH."
      exit 1
    fi
  done
}

# Yes/no prompt
function yesno() {
  local prompt="$@"
  local answer

  echo
  echo -n "${prompt} <y/n>? "
  read answer < /dev/tty
  answer=${answer^^}

  if [ "${answer}" == "Y" ]; then
    return 0
  else
    return 1
  fi
}

# Tests configuration
function test_config() {
  set +u

  if [ -z "${apache_conf_path}" ]; then
    echoerr "Error: Apache conf.d path not defined in ${conf_file}."
    exit 1
  elif [ ! -d "${apache_conf_path}" ]; then
    echoerr "Error: Apache conf.d path defined, but directory does not exist (${apache_conf_path})."
    exit 1
  fi

  if [ -z "${share_parent_path}" ]; then
    echoerr "Error: parent path for shares not defined in ${conf_file}."
    exit 1
  elif [ ! -d "${apache_conf_path}" ]; then
    echoerr "Error: parent path for shares defined, but does not exist (${apache_conf_path})."
    exit 1
  fi

  if [ -z ${share_name_length} ]; then
    echoerr "Error: share name max length is not defined."
    exit 1
  elif [ $(( share_name_length + 1 )) -eq 1 ]; then
    echoerr "Error: invalid value for share name max length (${share_name_length})"
    exit 1
  elif [ ${share_name_length} -lt ${share_name_min_length} ]; then
    echoerr "Error: share name max length too short (got ${share_name_length}, minimum is ${share_name_min_length})"
    exit 1
  elif [ ${share_name_length} -gt ${share_name_max_length} ]; then
    echoerr "Error: share name max length too short (got ${share_name_length}, maximum is ${share_name_max_length})"
    exit 1
  fi

  if [ -z ${share_password_length} ]; then
    echoerr "Error: share password max length is not defined."
    exit 1
  elif [ $(( share_password_length + 1 )) -eq 1 ]; then
    echoerr "Error: invalid value for share password max length (${share_name_length})"
    exit 1
  elif [ ${share_password_length} -lt ${share_password_min_length} ]; then
    echoerr "Error: share password max length too short (got ${share_password_length}, minimum is ${share_password_min_length}"
    exit 1
  elif [ ${share_password_length} -gt ${share_password_max_length} ]; then
    echoerr "Error: share password max length too long (got ${share_password_length}, maximum is ${share_password_max_length}"
    exit 1
  fi

  local dirs=( "${apache_conf_path}" "${share_parent_path}" )
  for dir in "${dirs[@]}" ; do
    if [ ! -d "${dir}" ]; then
      echoerr "Error: directory ${dir} does not exist."
      exit 1
    fi
  done

  set -u
}

# A file loader
function require() {
  local require_file="$1"

  export require_output

  if [ -f "${require_file}" ]; then
    if ! source "${require_file}" ; then
      echoerr "Error loading file ${require_file} - exiting."
      exit 1
    fi
  else
    echoerr "File ${require_file} not found, unable to continue."
    exit 1
  fi
}