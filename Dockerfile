FROM debian:bullseye-slim AS binary

LABEL authors="Erik Garrison, Christos Chatzifountas"
LABEL description="Preliminary docker image containing all requirements for bgwt"
LABEL base_image="debian:bullseye-slim"
LABEL about.home="https://github.com/pangenome/privacy-pangenomics"
LABEL about.license="SPDX:MIT"


SHELL ["/bin/bash", "-c"]

# odgi's dependencies

#

# RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1024R/D9D33FCD84D82C17288BA03B3C9A6980F827E01E

RUN apt-get update
# && apt-get install -y apt-utils wget

RUN apt-get install    -y \
                       perl\
                       git \
                       bash \
                       cmake \
                       make \
                       g++ \
                       build-essential \
                       time \
                       curl

RUN apt install -yy emacs elpa-racket-mode

# run apt-get install -y libdivsufsort libdivsufsort-dev

RUN git clone --recursive --depth=1 https://github.com/jltsiren/gbwtgraph
RUN ln -s gbwtgraph/deps/gbwt/deps/sdsl-lite ./sdsl-lite
RUN cd gbwtgraph/deps && ln -s gbwt/deps/sdsl-lite sdsl-lite  && ls -l
RUN cd gbwtgraph/deps/gbwt/deps/sdsl-lite && perl -pi -e '/\#\# Project information \#\#/ and $_.="set\(CMAKE_CXX_FLAGS \"-fPIC\"\)\n"' CMakeLists.txt && cmake . && make && make install
RUN cd gbwtgraph/deps/gbwt  && make \
                            && make install   \
                            && ./install /usr/local/
                            # && \ && ../

RUN cd  gbwtgraph/deps/libhandlegraph && cmake .  \
                                      && make CXXFLAGS="-fPIC"   \
                                      && make install

RUN cd gbwtgraph   && ls -l \
                   &&  perl -pi -e  's/make \-j \"\$\{JOBS\}\"/make CXXFLAGS\=\"\-fPIC\" \-j \"\$\{JOBS\}\"/g' install.sh  \
                   && ./install.sh /usr/local


RUN  git clone --depth=1 https://github.com/pangenome/gbwt-wrapper

RUN cd gbwt-wrapper \
                    &&    gcc -c -fPIC gbwt_wrapper.cpp; \
                      g++ -o libgbwtwrapper.so -Wl,--whole-archive \
                      /usr/local/lib/libgbwtgraph.a /usr/local/lib/libhandlegraph.a \
                      /usr/local/lib/libsdsl.a /usr/local/lib/libgbwt.a \
                      -Wl,--no-whole-archive -shared gbwt_wrapper.o -pthread -fopenmp  \
                    && cp libgbwtwrapper.so /usr/local/lib/


RUN curl -LO https://download.racket-lang.org/installers/8.2/racket-8.2-x86_64-linux-cs.sh

RUN bash racket-8.2-x86_64-linux-cs.sh \
    && rm -rf racket-8.2-x86_64-linux-cs.sh


RUN git clone --depth=1 https://github.com/pangenome/privacy-pangenomics

ENV PATH=$PATH:/usr/racket/bin


ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib



RUN  raco pkg install  --deps search-auto memo   describe   threading


RUN cd privacy-pangenomics && racket test.rkt


