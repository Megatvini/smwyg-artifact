FROM ubuntu:18.10

ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN sed -i -re 's/([a-z]{2}\.)?archive.ubuntu.com|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list

#RUN echo "deb http://old-releases.ubuntu.com/ubuntu/ cosmic main restricted universe multiverse" >> /etc/apt/sources.list && \
#echo "deb http://old-releases.ubuntu.com/ubuntu/ cosmic-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
#echo "deb http://old-releases.ubuntu.com/ubuntu/ cosmic-security main restricted universe multiverse" >> /etc/apt/sources.list

RUN apt-get update && \
 apt-get -y upgrade && apt-get -y install curl wget gnupg 
RUN rm -rf /var/lib/apt/lists/*
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key|apt-key add -

RUN echo "deb http://apt.llvm.org/cosmic/ llvm-toolchain-cosmic-6.0 main" >> /etc/apt/sources.list && \
    echo "deb-src http://apt.llvm.org/cosmic/ llvm-toolchain-cosmic-6.0 main" >> /etc/apt/sources.list

RUN apt-get update && \
    apt-get -y install tar xz-utils cmake ninja-build build-essential libffi-dev python  libboost1.67-all-dev git libssl-dev libncurses5-dev \
               python-pip radare2 time pandoc python3-setuptools python3-pip python3-tempita clang-7 lldb-7 lld-7 llvm-7 python-matplotlib glpk-utils libglpk-dev glpk-doc&& \
    rm -rf /var/lib/apt/lists/* && \
      mkdir -p /home/sip/ && \
      cd /home/sip/ && git clone https://github.com/nlohmann/json.git && mkdir -p /home/sip/json/build/ && cd /home/sip/json/build/ && cmake -DJSON_BuildTests=Off --config=Release .. && make && make install && cd /home/sip && rm -rf /home/sip/json/ && \
    pip install argparse numpy pandas r2pipe pwn benchexec==1.16 pypandoc && \
    pip3 install --upgrade pip && \
    pip3 install gensim==3.8.1 sklearn tabulate tensorflow==2.1.0 stellargraph==0.10.0 keras==2.3.1 tensorflow-cpu==2.1.0 tables && \
    wget https://github.com/sosy-lab/benchexec/releases/download/1.16/benchexec_1.16-1_all.deb && dpkg -i benchexec_*.deb && rm benchexec_*.deb
    
WORKDIR /
RUN curl http://lemon.cs.elte.hu/pub/sources/lemon-1.3.1.tar.gz --output lemon.tar.gz && \
    tar -xvzf lemon.tar.gz -C . && mkdir -p /lemon-1.3.1/build && cd /lemon-1.3.1/build && \
    sed -i '6i SET(CMAKE_POSITION_INDEPENDENT_CODE ON)' /lemon-1.3.1/CMakeLists.txt
RUN cd /lemon-1.3.1/build && cmake .. && make -j4 && make install

WORKDIR /home/sip
RUN git clone https://github.com/mr-ma/composition-function-filter.git function-filter && mkdir -p /home/sip/function-filter/build && cd /home/sip/function-filter/build && cmake --config=Release .. && make -j4 && make install 
RUN git clone -b smwyg https://github.com/mr-ma/composition-framework.git && mkdir -p /home/sip/composition-framework/build && cd /home/sip/composition-framework/build && cmake --config=Release .. && make -j4 && make install



RUN git clone https://github.com/mr-ma/composition-input-dependency-analyzer.git input-dependency-analyzer && mkdir -p /home/sip/input-dependency-analyzer/build && cd /home/sip/input-dependency-analyzer/build && cmake --config=Release .. && make -j4 && make install

RUN git clone https://github.com/tum-i22/dg.git && mkdir -p /home/sip/dg/build && cd /home/sip/dg/build && cmake .. && make -j4 && make install

RUN git clone -b acsac https://github.com/tum-i22/dg.git acsac-dg && mkdir -p /home/sip/acsac-dg/build && cd /home/sip/acsac-dg/build && cmake .. && make -j4 && make install


RUN git clone -b cleanup https://github.com/anahitH/SVF.git && mkdir -p /home/sip/SVF/build && cd /home/sip/SVF/build && cmake .. && make -j4 && make install

RUN git clone -b cleanup https://github.com/mr-ma/program-dependence-graph.git && mkdir -p /home/sip/program-dependence-graph/build && cd /home/sip/program-dependence-graph/build && cmake .. && make -j4 && make install

RUN git clone -b smwyg https://github.com/mr-ma/offtree-o-llvm && mkdir -p /home/sip/offtree-o-llvm/passes/build && cd /home/sip/offtree-o-llvm/passes/build && cmake .. && make -j4

RUN git clone -b smwyg https://github.com/mr-ma/composition-self-checksumming.git self-checksumming && mkdir -p /home/sip/self-checksumming/build && cd /home/sip/self-checksumming/build && cmake --config=Debug .. && make -j4 && make install
RUN git clone -b smwyg https://github.com/mr-ma/composition-sip-oblivious-hashing.git sip-oblivious-hashing && mkdir -p /home/sip/sip-oblivious-hashing/build && cd /home/sip/sip-oblivious-hashing/build && cmake --config=Release .. && make -j4
RUN git clone -b smwyg https://github.com/mr-ma/composition-sip-control-flow-integrity.git sip-control-flow-integrity && mkdir -p /home/sip/sip-control-flow-integrity/build && cd /home/sip/sip-control-flow-integrity/build && cmake --config=Release .. && make -j4
RUN git clone -b smwyg https://github.com/mr-ma/composition-sip-eval.git eval && mkdir -p /home/sip/eval/passes/build && cd /home/sip/eval/passes/build && cmake .. && make -j4
RUN cd /home/sip/self-checksumming/hook && make -j4

RUN git clone https://github.com/mr-ma/sip-ml

WORKDIR /home/sip/eval

#Download large programs generation of which requires a fast solver such as Gurobi
#Users can indeed generate these files using on their end by referring to the instructions given in the experimental branch of sip-composition-eval
RUN wget https://syncandshare.lrz.de/download/MlVoQlBpMXpVMnJQWVMzUzN0UWRU/LABELED-BCs.tar.gz
#RUN tar -xvf /home/sip/eval/LABELED-BCs.tar.gz -C /home/sip/eval/LABELED-BCs
#RUN rm -r /home/sip/eval/LABELED-BCs.tar.gz



CMD ["/bin/bash"]
