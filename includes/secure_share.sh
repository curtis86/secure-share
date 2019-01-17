## Secure Share Functions

# Generate a random string
function random_string() {
  local type=$1
  local length=$2

  case "${type}" in
    alpha) tr -cd '[:alpha:]' < /dev/urandom | fold -w ${length} | head -n1 | tr '[A-Z]' '[a-z]' ;; 
    alnum) tr -cd '[:alnum:]' < /dev/urandom | fold -w ${length} | head -n1 ;;
    complex) : ;;
  esac

  
}

function share_exists() {
  if [ -f "${share_config_dir}/${name}" ]; then
    echoerr "Error: share name ${name} already exists."
    exit 1
  elif [ -d "${share_parent_path}/${name}" ]; then
    echoerr "Error: share name ${name} already exists."
    exit 1
  else
    return 1
  fi
}

function generate_share() {
  export name password _expiration path config

  is_unique=1
  gen_retries=0
  gen_retries_max=5

  while [ ${is_unique} -eq 1 ]; do
    if ! share_exists "${name}" ; then
      is_unique=0
    else
      echoerr "Error: share name already exists."
      echo -n "Enter a new name: "
      read name < /dev/tty
    fi
    ((gen_retries++))
    if [ ${gen_retries} -ge ${gen_retries_max} ]; then
      echoerr "Error: unable to generate a unique name."
      exit 1
    fi
  done

  password="$( random_string alnum ${p} )"
  path="${share_parent_path}/${name}"
  config="${share_config_dir}/${name}.conf"

  generate_config
}

# Checks if conf for Apache is installed
function check_apache_config_installed() {
  if [ ! -f "${apache_conf_path}/secure-share.conf" ]; then
    return 1
  else
    return 0
  fi
}

# Create a dummy conf file
function create_dummy_conf() {
  touch "${share_config_dir}/dummy.conf"
}

# Test Apache config
function apache_conf_test() {
  if ! httpd -t >/dev/null 2>&1 ; then
    echoerr "Error: Apache configuration test failed."
    echoerr "This means that there is currently an error in your Apache configuration."
    echoerr "${progname} is unable to add shares to a broken Apache config. Please fix before retrying."
    echoerr "To see the Apache configuration error, run \"httpd -t\""
    exit 1
  fi
}

# Installs parent config for Apache
function install_apache_config() {
  local apache_conf_file="${apache_conf_path}/secure-share.conf"
  local APACHE_TEMPLATE="
# Do not edit - this may be modified by secure-share script.
Include ${share_config_dir}/*.conf"

  if ! check_apache_config_installed ; then
    if [ ${force} -eq 0 ] || yesno "Install Apache config to ${apache_conf_file}" ; then
      touch "${apache_conf_file}"
      echo "${APACHE_TEMPLATE}" > "${apache_conf_file}"
      echo "Apache config installed!"
    else
      echo "Warning: if the Apache config is not installed, shares will not work."
    fi
  fi
}

# Restart Apache
function restart_apache() {
  export apache_test
  if apache_test="$( httpd -t 2>&1 )" ; then
    if [ ${force} -eq 0 ] || yesno "Restart Apache" ; then
      if apachectl restart ; then
        echo "Apache restarted."
      else
        echoerr "Error: unable to restart Apache"
        exit 1
      fi
    else
      echoerr "Warning: if Apache is not restarted, new shares may not be taken in to effect."
    fi
  fi
}

function verify_password_length() {
  if [ $(( password_length + 1000 )) -eq 1000 ]; then
    echoerr "Error: invalid password length: ${password_length}"
    exit 1
  elif [ ${password_length} -lt ${share_password_min_length} ]; then
    echoerr "Error: password length too short (min: ${share_password_min_length})"
    exit 1
  elif [ ${password_length} -gt ${share_password_max_length} ]; then
    echoerr "Error: password length too long (max: ${share_password_max_length})"
    exit 1
  fi
}

function verify_share_name() {

  name_clean="$( echo "${name}" | tr -cd '[[:alnum:]]._-' )"

  if [ "${name}" != "${name_clean}" ]; then
    echoerr "Error: share name \"${name}\" includes invalid characters."
    echoerr "Please use alphanumeric, dashses and underscores only."
    exit 1
  fi

  if [ ${#name} -lt ${share_name_min_length} ]; then
    echoerr "Error: share name too short (min: ${share_name_min_length})"
    exit 1
  elif [ ${#name} -gt ${share_name_max_length} ]; then
    echoerr "Error: share name too long (max: ${share_name_max_length})"
    exit 1
  fi
}

function confirm_create_share() {
  echo
  echo "Name: ${name}"
  echo "Username: ${username}"
  echo "Password: ${password}"
  #echo "Path: ${path}"

  [ ${force} -eq 0 ] && create_config && return 0

  if yesno "Create share with the above details?" ; then
    create_config
  else
    echo "Exiting."
    exit 0
  fi
}

function create_config() {
  local config_file="${share_config_dir}/secure-share-${name}.conf"
  local password_file="${share_config_dir}/secure-share-${name}.htpasswd"

  [ -f "${config_file}" ] && { echoerr "Error: config file ${config_file} already exists. Exiting." && exit 1 ;}
  [ -f "${password_file}" ] && { echoerr "Error: password file ${password_file} already exists. Exiting." && exit 1 ;}
  
  set -u

  if ! mkdir -p "${share_parent_path}/${name}" ; then
    echoerr "Error: unable to create share directory ${share_parent_path}/${name}"
    exit 1
  fi

  if ! touch "${config_file}" ; then
    echoerr "Error: unable to create config file."
    exit 1
  else
    echo "# This config was generated by secure-share
<Directory \"${share_parent_path}/${name}\">
  AuthType Basic
  AuthName \"Password Protected Area\"
  AuthUserFile "${password_file}"
  Require valid-user
</Directory>" >> "${config_file}"
  fi

  if ! touch "${password_file}" ; then
    echoerr "Error: unable to create password file, ${password_file}"
    exit 1
  else
    echo "$( htpasswd -b -n "${username}" "${password}" )" >> "${password_file}"
  fi

  echo "Share \"${name}\" created!" && conf_changed=0
}