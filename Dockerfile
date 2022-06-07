FROM debian:bookworm-slim AS binary

LABEL authors="Erik Garrison, Christos Chatzifountas"
LABEL description="Preliminary docker image containing all requirements for bgwt"
LABEL base_image="debian:bullseye-slim"
LABEL about.home="https://github.com/pangenome/privacy-pangenomics"
LABEL about.license="SPDX:MIT"


SHELL ["/bin/bash", "-c"]



RUN apt-get update
# RUN apt-get install -yy netselect-apt

# RUN netselect-apt -c germany -t 15 -a amd64 -n bullseye-slim
RUN apt-get install -yy rsync gnupg gnupg2 gnupg1

RUN apt-get install -yy perl

RUN apt-get install -yy libexpat1

RUN apt-get install -yy git

RUN apt-get install -yy bash

RUN apt-get install -yy cmake make

RUN apt-get install -yy  gcc-11 g++-11 build-essential time curl

RUN apt install -yy emacs elpa-racket-mode


RUN  mkdir -p /usr/local/include/handlegraph
RUN  mkdir -p /usr/local/include/sdsl-lite
# RUN mkdir -p /usr/local/include/gbwtgraph


RUN git clone https://github.com/jltsiren/gbwtgraph    && cd gbwtgraph && git checkout e13a561
RUN git clone --depth=1 https://github.com/vgteam/sdsl-lite
RUN git clone --depth=1 https://github.com/jltsiren/gbwt
RUN git clone https://github.com/vgteam/libhandlegraph && cd libhandlegraph && git checkout 521ec5a



ENV PATH="/usr/local/bin:${PATH}"

ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

ENV CPATH ="/usr/local/include/gbwt:/usr/local/include/gbwtgraph:/usr/local/include/handlegraph:/usr/local/include/ldsl-lite/"

# copy include directories

# RUN mkdir -p /usr/local/include/gbwtgraph


RUN cd sdsl-lite && perl -pi -e '/\#\# Project information \#\#/ and $_.="set\(CMAKE_CXX_FLAGS \"-fPIC\"\)\n"' CMakeLists.txt && cmake . && make && make install


RUN  rsync -av  sdsl-lite/include/sdsl /usr/local/include/sdsl-lite

RUN cd gbwt &&  rsync -av include/gbwt /usr/local/include  \
            && make \
            && make install   \
            && ./install /usr/local/


RUN cd  libhandlegraph  && rsync -av src/include/* /usr/local/include/handlegraph/ \
                        && cmake .  \
                        && make CXXFLAGS="-fPIC"   \
                        && make install

RUN ls /usr/local/include/handlegraph/
RUN cd gbwtgraph   && rsync -av include/gbwtgraph /usr/local/include  \
                   && ls -l \
                   &&  perl -pi -e  's/make \-j \"\$\{JOBS\}\"/make CXXFLAGS\=\"\-fPIC\" \-j \"\$\{JOBS\}\"/g' install.sh  \
                   && ./install.sh /usr/local


RUN curl -LO https://gist.githubusercontent.com/Gavlooth/f37bb312c5d163b1d889cdb6fd7b4df5/raw/be069a41da7c5ff3bc9138541af6ca4f4ddb7cc0/gbwtgraph.i

RUN apt-get install -yy libpcre++-dev

RUN curl -LO https://altushost-swe.dl.sourceforge.net/project/swig/swig/swig-4.0.2/swig-4.0.2.tar.gz \
    && tar -zxvf swig-4.0.2.tar.gz \
    && cd swig-4.0.2 \
    && ./configure --prefix="/usr/local/" \
    && make  \
    && make install

RUN cd /usr/local/include \
    && find ./ | xargs -I % perl -pi -e 's/static const /const static /g' %


RUN perl -pi -e 's/^\[\[deprecated/\/\/\[\[deprecated/' /usr/local/include/handlegraph/types.hpp

RUN curl -LO https://racket.infogroep.be/8.2/racket-8.2-src-builtpkgs.tgz

RUN tar -zxvf racket-8.2-src-builtpkgs.tgz

RUN cd racket-8.2/src  && ./configure --enable-bcdefault  --enable-cgcdefault --enable-shared --prefix="/usr/local/" && make  both -j 12 && make install-both

RUN ls -l /usr/local/bin

RUN swig -c++ -v -mzscheme -declaremodule  gbwtgraph.i;

RUN raco ctool ++ccf  -fpermissive ++ccf -lstdc++  --cc --cgc  gbwtgraph_wrap.cxx ;

RUN g++ -o gbwtgraph.so -Wl,--whole-archive \
                    /usr/local/lib/libgbwtgraph.a \
                    /usr/local/lib/libhandlegraph.a \
                    /usr/local/lib/libsdsl.a \
                    /usr/local/lib/libgbwt.a -Wl,--no-whole-archive -shared  /usr/local/lib/racket/mzdyn.o  gbwtgraph_wrap.o  -pthread -fopenmp

RUN MODULEPATH=$(racket -e '(string->symbol (path->string (build-path "compiled" "native" (system-library-subpath))))' | cut -c2-) \
               && mkdir -p  $MODULEPATH \
               && mv gbwtgraph.so  $MODULEPATH


RUN mkdir -p privacy-pangenomics && rsync -av  compiled ../privacy-pangenomics/


WORKDIR "privacy-pangenomics"

curl -LO https://gist.githubusercontent.com/Gavlooth/100319e862ac8ab07ae1f161c21c174f/raw/747b835082e5e886c59b3c1fa9d4b160ab8c13ab/privacy.rkt

