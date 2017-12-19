FROM debian:jessie

# docker build -t db-deps .

MAINTAINER IBM Cloudant <support@cloudant.com>

ENV OTP_VERSION=17.5 \
    OTP_REPO=https://github.com/erlang/otp.git \
    OTP_OPTIONS="--enable-dirty-schedulers" \
    CSMAP_VSN=14.01 \
    CSMAP_REPO=http://svn.osgeo.org/metacrs/csmap/branches/14.01/CsMapDev@2471 \
    SPATIALINDEX_ARCHIVE=1.9.3-4-cloudant.tar.gz \
    SPATIALINDEX_URL=https://github.com/cloudant/libspatialindex/archive \
    CLOUSEAU_REPO=https://github.com/cloudant-labs/clouseau.git \
    PREFIX=/usr/local \
    MAKEFLAGS="-j8"

WORKDIR /opt

RUN apt-get -qq update && \
    apt-get install -qq -y --force-yes --no-install-recommends \
    # git
    ca-certificates \
    git \
    libncurses-dev \
    # OTP build
    autoconf \
    build-essential \
    # crypto ciphers
    libssl-dev \
    # couchjs
    libmozjs185-1.0 \
    libmozjs185-dev \
    libicu52 \
    libicu-dev \
    # cloudant configure
    ssh \
    python2.7 \
    python-pip \
    virtualenv \
    # clouseau (search)
    openjdk-7-jdk \
    maven \
    # csmap
    subversion \
    # spatialindex
    automake \
    libtool \
    # easton (geo)
    libgeos-dev \
    libgeos++-dev \
    libleveldb-dev \
    # testy
    python-dev \
    libyaml-dev \
    # misc
    haproxy \
    jq \
    curl \
    wget && \
    # cloudant configure
    pip install jinja2 PyYAML && \
    # testy
    pip install --upgrade setuptools && \
    pip install \
        argparse==1.4.0 \
        arrow==0.10.0 \
        babel==2.5.0 \
        deepdiff==3.3.0 \
        dnspython==1.15.0 \
        docopt==0.6.2 \
        fabric==1.13.2 \
        flaky==3.4.0 \
        mock==2.0.0 \
        parameterized==0.6.1 \
        pycrypto==2.6.1 \
        PyHamcrest==1.9.0 \
        pytest-cov==2.5.1 \
        pytest-pep8==1.0.6 \
        pytest-timeout==1.2.0 \
        pytest==3.2.1 \
        requests-futures==0.9.7 \
        requests==2.18.4 \
        retrying==1.3.3 \
        shapely==1.6.0 \
        texttable==0.9.1 \
        unidecode==0.4.21 \
        wsgiref==0.1.2 \
        ConfigArgParse==0.12.0

RUN git clone $OTP_REPO && \
    cd otp && \
    git checkout OTP-${OTP_VERSION} && \
    export ERL_TOP=`pwd` && \
    ./otp_build autoconf ${OTP_OPTIONS} && \
    ./configure ${OTP_OPTIONS} && \
    MAKEFLAGS=$MAKEFLAGS make && \
    make install


# csmap

RUN svn co $CSMAP_REPO csmap

COPY csmap-${CSMAP_VSN}/csepsgstuff.h csmap/Include/
COPY csmap-${CSMAP_VSN}/csEpsgStuff.cpp csmap/Source/
COPY csmap-${CSMAP_VSN}/Library.mak csmap/Source/
COPY csmap-${CSMAP_VSN}/CS_COMP.diff csmap/Dictionaries/

RUN cd csmap/Source && make -fLibrary.mak && \
    cd ../Dictionaries && patch -p0 -i CS_COMP.diff && make -fCompiler.mak && \
    ./CS_Comp . . && cd .. && \
    mkdir -p $PREFIX/include/CsMap && cp -R Include/* $PREFIX/include/CsMap/ && \
    mkdir -p $PREFIX/lib && cp Source/CsMap.a $PREFIX/lib/libCsMap.a && \
    mkdir -p $PREFIX/share/CsMap/dict && cp -r Dictionaries/* $PREFIX/share/CsMap/dict/


# spatialindex

RUN mkdir libspatialindex && cd libspatialindex && \
    wget --no-check-certificate $SPATIALINDEX_URL/$SPATIALINDEX_ARCHIVE && \
    tar -x --strip-components=1 -zf $SPATIALINDEX_ARCHIVE && \
    ./autogen.sh && ./configure && make install


# # clouseau

# RUN git clone $CLOUSEAU_REPO && \
#     cd clouseau && mvn
