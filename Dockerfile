FROM debian:11 as download-samblaster
ARG SAMBLASTER_VERSION=0.1.26
RUN apt-get update -y && apt-get install -y curl tar
RUN curl -OL https://github.com/GregoryFaust/samblaster/releases/download/v.${SAMBLASTER_VERSION}/samblaster-v.${SAMBLASTER_VERSION}.tar.gz
RUN tar xzf samblaster-v.${SAMBLASTER_VERSION}.tar.gz

FROM debian:11 as build-samblaster
RUN apt-get update -y && apt-get install -y tar build-essential
ARG SAMBLASTER_VERSION=0.1.26
COPY --from=download-samblaster /samblaster-v.${SAMBLASTER_VERSION} /samblaster-v.${SAMBLASTER_VERSION}
WORKDIR /samblaster-v.${SAMBLASTER_VERSION}
RUN make

FROM debian:11 as download-samtools
ARG SAMTOOLS_VERSION=1.14
RUN apt-get update -y && apt-get install -y curl tar bzip2
RUN curl -OL https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2
RUN tar xjf samtools-${SAMTOOLS_VERSION}.tar.bz2

FROM debian:11 as build-samtools
ARG SAMTOOLS_VERSION=1.14
RUN apt-get update -y && apt-get install -y tar build-essential libncurses-dev libcurl4-openssl-dev liblzma-dev libbz2-dev zlib1g-dev
COPY --from=download-samtools /samtools-${SAMTOOLS_VERSION} /samtools-${SAMTOOLS_VERSION}
WORKDIR /samtools-${SAMTOOLS_VERSION}
RUN ./configure
RUN make -j4
RUN make install

FROM debian:11-slim
RUN apt-get update -y && apt-get install -y libncursesw6 libncurses6 libcurl4 liblzma5 bzip2 zlib1g libdigest-perl-md5-perl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
ARG SAMBLASTER_VERSION=0.1.26
COPY --from=build-samblaster /samblaster-v.${SAMBLASTER_VERSION}/samblaster /usr/local/bin/samblaster
COPY --from=build-samtools /usr/local /usr/local
ENV PATH=/opt/bwa-mem2-${BWAMEM2_VERSION}_x64-linux:$PATH
