ARG DEBIAN_VERSION=11
FROM debian:${DEBIAN_VERSION}

ARG CLAMAV_VERSION

LABEL \
    maintainer="g0dsCookie <g0dscookie@cookieprojects.de>" \
    description="An open source antivirus engine for detecting trojans, viruses, malware & other malicious threats" \
    version="${CLAMAV_VERSION}"

COPY talos.key /tmp/talos.key

RUN set -eu \
 && CLAMAV_VERSION="$(echo ${CLAMAV_VERSION} | sed 's/^v//')" \
 && echo "${CLAMAV_VERSION}" >ver \
 && IFS='.' read MAJOR MINOR PATCH <ver && rm -f ver \
 && cecho() { echo "\033[1;32m$1\033[0m"; } \
 && cecho "### PREPARE ENVIRONMENT ###" \
 && TMP="$(mktemp -d)" && PV="${CLAMAV_VERSION}" && S="${TMP}/clamav-${PV}" \
 && useradd -d /var/lib/clamav -M -r clamav \
 && mkdir -p /var/lib/clamav /run/clamav \
 && chown clamav:clamav /var/lib/clamav /run/clamav && chmod 0700 /var/lib/clamav /run/clamav \
 && cecho "### INSTALLING DEPENDENCIES ###" \
 && apt-get update -qq \
 && apt-get install -qqy \
        build-essential cmake curl gnupg check \
        libssl-dev libcurl4-openssl-dev zlib1g-dev libpng-dev \
        libjson-c-dev libbz2-dev libpcre2-dev ncurses-dev libxml2-dev \
        libmilter-dev python3-dev \
 && apt-get install -qqy \
        libcurl4 libjson-c5 libpcre2-8-0 libncurses6 libmilter1.0.1 libxml2 zlib1g python3 \
 && cecho "### IMPORTING GPG KEYS ###" \
 && gpg --import /tmp/talos.key && rm -f /tmp/talos.key \
 && cecho "### DOWNLOADING CLAMAV ###" \
 && curl -sSL --output "${TMP}/clamav-${PV}.tar.gz" "https://www.clamav.net/downloads/production/clamav-${PV}.tar.gz" \
 && curl -sSL --output "${TMP}/clamav-${PV}.tar.gz.sig" "https://www.clamav.net/downloads/production/clamav-${PV}.tar.gz.sig" \
 && cd ${TMP} \
 && cecho "### VERIFY SIGNATURE ###" \
 && gpg --verify "clamav-${PV}.tar.gz.sig" "clamav-${PV}.tar.gz" \
 && tar -xf "clamav-${PV}.tar.gz" \
 && cecho "### BUILDING CLAMAV ###" \
 && cd "clamav-${PV}" \
 && mkdir build && cd build \
 && cmake .. \
       -D CMAKE_INSTALL_PREFIX=/usr \
       -D CMAKE_INSTALL_LIBDIR=lib \
       -D APP_CONFIG_DIRECTORY=/etc/clamav \
       -D DATABASE_DIRECTORY=/var/lib/clamav \
       -D ENABLE_JSON_SHARED=OFF \
       -D ENABLE_SYSTEMD=OFF \
       -D ENABLE_MILTER=ON \
       -D ENABLE_CLAMONACC=ON \
       -D CLAMAV_USER=clamav -D CLAMAV_GROUP=clamav \
 && cmake --build . \
 && cmake --build . --target install \
 && cecho "### COPY CONFIG ###" \
 && sed \
        -e "s:^\(Example\):\# \1:" \
        -e "s:.*\(PidFile\) .*:\1 /run/clamav/freshclam.pid:" \
        -e "s:^\#\(LogTime\).*:\1 yes:" \
        -e "s:.*\(DatabaseOwner\) .*:\1 clamav:" \
        -e "s:^\#\(NotifyClamd\).*:\1 /etc/clamav/clamd.conf:" \
        -e "s:^\#\(ScriptedUpdates\).*:\1 yes:" \
        -e "s:^\#\(AllowSupplementaryGroups\).*:\1 yes:" \
        /etc/clamav/freshclam.conf.sample >/etc/clamav/freshclam.conf \
 && sed \
        -e "s:^\(Example\):\# \1:" \
        -e "s:.*\(PidFile\) .*:\1 /run/clamav/clamd.pid:" \
        -e "s:.*\(LocalSocket\) .*:\1 /run/clamav/clamd.sock:" \
        -e "s:.*\(LocalSocketMode\) .*:\1 660:" \
        -e "s:.*\(TCPSocket\) .*:\1 3310:" \
        -e "s:.*\(TCPAddr\) .*:\1 0.0.0.0:" \
        -e "s:.*\(User\) .*:\1 clamav:" \
        -e "s:^\#\(LogTime\).*:\1 yes:" \
        -e "s:^\#\(AllowSupplementaryGroups\).*:\1 yes:" \
        /etc/clamav/clamd.conf.sample >/etc/clamav/clamd.conf \
 && cecho "### CLEANUP ###" \
 && cd && rm -rf "${TMP}" \
 && apt-get remove -qqy \
        build-essential cmake curl gnupg check \
        libssl-dev libcurl4-openssl-dev zlib1g-dev libpng-dev \
        libjson-c-dev libbz2-dev libpcre2-dev ncurses-dev libxml2-dev \
        libmilter-dev python3-dev \
 && apt-get autoremove -qqy \
 && apt-get clean -qqy

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 3310/tcp
VOLUME [ "/etc/clamav", "/var/lib/clamav" ]

USER clamav
ENTRYPOINT [ "/docker-entrypoint.sh" ]