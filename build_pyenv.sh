#!/bin/bash

# Enable set to be sure that all command don't fail
set -eu

# Chroot config
dir_name="pgadmin"
path_to_build="/opt/yunohost/$dir_name/venv"

#################################################################

app_version="$1"
result_prefix_name="$2"

if [[ ! "$@" =~ "chroot-yes" ]]
then
	echo "Est vous bien dans un chroot ? [y/n]"
	read a
	if [[ $a != "y" ]]
	then
		echo "Il est fortement conseillé d'être dans un chroot pour faire ces opérations"
		exit 0
	fi
fi

# Mount proc if it'isnt mouned.
if [[ $(mount) != *"proc on /proc type proc"* ]]
then
	mount -t proc proc /proc
fi

# Upgrade system
apt-get update
apt-get dist-upgrade -y
apt-get install -y build-essential python3-dev libffi-dev python3-pip python3-setuptools sqlite3 libssl-dev python3-venv libjpeg-dev libpq-dev postgresql libgcrypt20-dev libpq-dev curl libkrb5-dev pkg-config zip

# Clean environnement
rm -rf $path_to_build
rm -rf ~/.cache/pip

echo "Start build time : $(date)" >> PgAdmin_build_stat_time.log

# Install rustup to build crytography
if [ -z $(which rustup) ]; then
    curl -sSf -L https://static.rust-lang.org/rustup.sh | sh -s -- -y --default-toolchain=stable --profile=minimal
else
    rustup update
fi
source $HOME/.cargo/env

# Create new environnement
mkdir -p $path_to_build
python3 -m venv --copies $path_to_build

# Patch pip archive
pip3 download --no-deps pgadmin4==$app_version
rm -rf wheel_archive
mkdir -p wheel_archive
pushd wheel_archive
unzip -q ../pgadmin4-$app_version-py3-none-any.whl
rm -r ../pgadmin4-$app_version-py3-none-any.whl
sed -i  's|psycopg\[binary\]|psycopg[c]|g' pgadmin4-*.dist-info/METADATA
zip -r -q ../pgadmin4-$app_version-py3-none-any.whl *
popd
rm -r wheel_archive

# Go in virtualenv
old_pwd="${PWD/%\//}"
pushd $path_to_build
set +u; source bin/activate; set -u

# Install source and build binary
pip3 install --upgrade pip wheel
pip3 install --upgrade gunicorn
# pip3 install --upgrade pgadmin4==$app_version
pip3 install --upgrade $old_pwd/pgadmin4-$app_version-py3-none-any.whl
pip3 freeze | grep -v 'pkg_resources' | sed "s|pgadmin4\s*@\s*file:.*|pgadmin4==$app_version|g" > $old_pwd/${result_prefix_name}-build1_requirement.txt

# Quit virtualenv
set +u; deactivate; set -u
cd ..

# Build archive of binary
tar -czf "${result_prefix_name}-bin1_armv7l.tar.gz" "$dir_name"
sha256sumarchive=$(sha256sum "${result_prefix_name}-bin1_armv7l.tar.gz" | cut -d' ' -f1)
mv "${result_prefix_name}-bin1_armv7l.tar.gz" "$old_pwd"/
echo $sha256sumarchive > "$old_pwd/${result_prefix_name}-bin1_armv7l-sha256.txt"

popd

echo "Finish build time : $(date)" >> PgAdmin_build_stat_time.log
echo "sha256 SUM : $sha256sumarchive"

exit 0
