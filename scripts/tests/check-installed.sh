#!/bin/bash

# @Tech Logicals
set -eu

#
# Check that all the packages in ../packages actually exist.
#

PKGDIR=../packages
MISSING=false

for FILE in "${PKGDIR}"/*; do
  basename "${FILE}"

  # Skip the wine list if multilib is not enabled.
  if [[ "${FILE}" = "../packages/wine.list" ]]; then
    if ! pacman -Sl multilib > /dev/null 2>&1; then
      echo "[multilib] not enabled. Skipping."
      echo
      continue
    fi
  fi

  while read -r PACKAGE; do
    METACOUNT=$(pacman -Ss "${PACKAGE}" |
                grep -c "(.*${PACKAGE}.*)" || true)
    INSTALLCOUNT=$(pacman -Qs "${PACKAGE}" |
                   grep -c "^local.*(.*${PACKAGE}.*)$" || true)

    # Check if package is installed.
    if pacman -Qi "${PACKAGE}" > /dev/null 2>&1; then
      echo -e "\033[1;35m✓\033[0m" "${PACKAGE}"

    # pacman -Qi won't work with meta packages, so check if all meta package
    # members are installed instead.
    elif [[ (${INSTALLCOUNT} -eq ${METACOUNT}) && ! (${INSTALLCOUNT} -eq 0) ]]; then
      echo -e "\033[1;35m✓\033[0m" "${PACKAGE}"

    # Runs if package is not installed or all members of meta-package are not
    # installed.
    else
      MISSING=true
      echo -e "\033[1;31m✗ ${PACKAGE}\033[m"
    fi
  done < "${FILE}"

  echo
done

if ${MISSING}; then
  exit 1
fi
