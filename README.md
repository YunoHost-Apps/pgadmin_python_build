Build script for pgadmin arm
=============================

This is a part of the project :  https://github.com/YunoHost-Apps/pgadmin_ynh
This is a script with provide a virtualenv already built for arm arch with all dependance. It improve the time of pgadmin package installation on slow arch.

The script build_pyenv.sh is used to build the release package.

How to
------

### Prerequist

The build need a really clean environnement so it's recommended to use a chroot. 

### Preparation

- Install the dependance :
```
apt install -y build-essential python3-dev libffi-dev python3-pip python3-setuptools sqlite3 libssl-dev python3-venv libjpeg-dev libpq-dev postgresql libgcrypt11-dev libgcrypt20-dev
```

- Clone the git repository.

- Lauch the build script by this command : `bash build_pyenv.sh`

- If nothing fail you should find a file named `matrix-pgadmin_x.x.x-bin1_ARCH.tar.gz` in the same dir then your script.
