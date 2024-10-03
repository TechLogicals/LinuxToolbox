#!/bin/bash

# @tech logicals
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
    if pacman -Ss ^"${PACKAGE//+/\\\+}"$ > /dev/null; then
      echo -e "\033[1;35m✓\033[0m" "${PACKAGE}"
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
