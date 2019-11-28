#!/bin/bash
#Copyright 2016  Tsinghua University (Author: Dong Wang, Xuewei Zhang).  Apache 2.0.

#decoding wrapper for thchs30 recipe
#run from ../

nj=8
mono=false

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ./path.sh ## Source the tools/utils (import the queue.pl)

. utils/parse_options.sh || exit 1;
decoder_word=$1
decoder_morpheme=$2
srcdir=$3
datadir=$4


if [ $mono = true ];then
  echo  "using monophone to generate graph"
  opt="--mono"
fi

#decode word
utils/mkgraph.sh $opt data/graph/lang $srcdir $srcdir/graph_word  || exit 1;
$decoder_word --cmd "$decode_cmd" --nj $nj $srcdir/graph_word $datadir/test $srcdir/decode_test_word || exit 1;

#decode morpheme
utils/mkgraph.sh $opt data/graph_morpheme_s/lang $srcdir $srcdir/graph_morpheme_s || exit 1;
$decoder_morpheme --cmd "$decode_cmd" --nj $nj $srcdir/graph_morpheme_s data/graph_morpheme_s/lang/G.fst data/graph_morpheme/lang/G.fst \
  $datadir/test $srcdir/decode_test_morpheme || exit 1;
local/wer_morph-to-word.sh $srcdir/decode_test_morpheme || exit 1;
