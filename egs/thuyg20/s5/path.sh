export KALDI_ROOT=`pwd`/../../..
[ -f $KALDI_ROOT/tools/env.sh ] && . $KALDI_ROOT/tools/env.sh

export PATH=$PWD/utils/:$KALDI_ROOT/src/bin:$KALDI_ROOT/src/lmbin:$KALDI_ROOT/src/chainbin:$KALDI_ROOT/src/ivectorbin:$KALDI_ROOT/src/kwsbin:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/src/fstbin/:$KALDI_ROOT/src/gmmbin/:$KALDI_ROOT/src/featbin/:$KALDI_ROOT/src/lm/:$KALDI_ROOT/src/sgmmbin/:$KALDI_ROOT/src/sgmm2bin/:$KALDI_ROOT/src/fgmmbin/:$KALDI_ROOT/src/latbin/:$KALDI_ROOT/src/lat:$KALDI_ROOT/src/nnetbin:$KALDI_ROOT/src/nnet2bin:$KALDI_ROOT/src/nnet3bin:$KALDI_ROOT/src/online2bin:$KALDI_ROOT/src/onlinebin:$KALDI_ROOT/src/rnnlmbin/:$KALDI_ROOT/src/hmm/:$KALDI_ROOT/src/ivector/:$KALDI_ROOT/src/lib/:$KALDI_ROOT/src/cudamatrix/:$KALDI_ROOT/src/fstext/:$KALDI_ROOT/src/gmm/:$KALDI_ROOT/src/decoder/:$KALDI_ROOT/src/feat/:$KALDI_ROOT/src/chain/:$KALDI_ROOT/src/base/:$KALDI_ROOT/src/tfrnnlmbin/:$PWD:$PATH

export LC_ALL=C

