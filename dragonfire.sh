#!/usr/bin/env bash

##
# DragonFire – Auto-publisher of Spike scrolls
# 
# Copyright © 2013  Mattias Andrée (maandree@member.fsf.org)
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
##


stderr=/dev/stderr
if [ "$(realpath /dev/stderr)" = "$(realpath /dev/stdout)" ]; then
    stderr=/dev/null
fi

git_commit_function = _git_commit
_git_commit ()
{
    git commit -m "$*"
}

. "/etc/dragonfirerc"

if [ -z "${SPOOL_REPO}" ]; then
    echo 'Fatal: Field SPOOL_REPO not defined in /etc/dragonfirerc' | tee $stderr
    exit 1
fi

while true; do
    read -r line
    if [ ! $? = 0 ]; then # Exit on EOF
	if [ $? = 1 ]; then
	    exit 0
	else
	    exit $?
	fi
    fi
    
    pkgname="$(cut -d ' ' -f 1 <<< "${line}")"
    pkgver="$(cut -d ' ' -f 2 <<< "${line}")"
    scrollfile="$(cut -d ' ' -f 1,2 --complement <<< "${line}")"
    
    line="$(cat -- /etc/dragonfire | grep -- "^${pkgname} ")"
    if [ ! $? = 0 ]; then
	echo "Cannot publish ${pkgname}: category not specified in /etc/dragonfire"
    else
	category="$(cut -d ' ' -f 1 --complement <<< "${line}")"
	cp "${scrollfile}" "${SPOOL_REPO}/${category}"
	cd "${SPOOL_REPO}"
	git add "${category}/${pkgname}.scroll" &&
	$git_commit_function "Update ${pkgname} to version ${pkgver}"
	if [ ! $? = 0 ]; then
	    echo "Cannot stage and commit ${pkgname}"
	else
	    rm -- "${scrollfile}" || echo "Cannot unspool ${scrollfile}"
	fi
	cd -
    fi
done

