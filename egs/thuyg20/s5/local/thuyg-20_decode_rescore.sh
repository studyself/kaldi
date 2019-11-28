#!/bin/bash
#Copyright 2016  Tsinghua University (Author: Dong Wang, Xuewei Zhang).  Apache 2.0.

#decoding wrapper for thchs30 recipe
#run from ../

nj=1
mono=false

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ./path.sh ## Source the tools/utils (import the queue.pl)

. utils/parse_options.sh || exit 1;
decoder_word=$1
decoder_morpheme=$2
srcdir=$3
datadir=$4

#####test tri1 model
####local/thuyg-20_decode.sh --nj $n "steps/decode.sh" "steps/decode_biglm.sh" exp/tri1 data/mfcc &

###### test tri3b model
##### local/thuyg-20_decode.sh --nj $n "steps/decode_fmllr.sh" "steps/decode_biglm.sh" exp/tri3b data/mfcc &

if [ $mono = true ];then
  echo  "using monophone to generate graph"
  opt="--mono"
fi

#######################decode word
utils/mkgraph.sh $opt data/graph/lang $srcdir $srcdir/graph_word  || exit 1;
$decoder_word --cmd "$decode_cmd" --nj $nj $srcdir/graph_word $datadir/test $srcdir/decode_test_word || exit 1;
### $decode_cmd = steps/decode.sh
### $srcdir = exp/tri1
### $datadir = data/mfcc

#################decode morpheme with BigLM tehnique, Large G - Small G' = F, HCLG compose F get the result
utils/mkgraph.sh $opt data/graph_morpheme_s/lang $srcdir $srcdir/graph_morpheme_s || exit 1;
$decoder_morpheme --cmd "$decode_cmd" --nj $nj $srcdir/graph_morpheme_s data/graph_morpheme_s/lang/G.fst data/graph_morpheme/lang/G.fst \
  $datadir/test $srcdir/decode_test_morpheme || exit 1;
local/wer_morph-to-word.sh $srcdir/decode_test_morpheme || exit 1;

#################################decode morpheme with rescoring --- begin
########## make small LM graphe G.fst
#####utils/mkgraph.sh $opt data/graph_morpheme_s/lang $srcdir $srcdir/graph_morpheme_s || exit 1;
#####
###### first pass, decoding with a small language model
#####$decoder_word --cmd "$decode_cmd" --nj $nj $srcdir/graph_morpheme_s $datadir/test $srcdir/decode_test_morpheme_1stPass || exit 1;
#####local/wer_morph-to-word.sh $srcdir/decode_test_morpheme_1stPass || exit 1;

###### second pass, rescoring with a large language model
#####steps/lmrescore.sh --cmd "$decode_cmd" \
#####  data/graph_morpheme_s/lang \
#####  data/graph_morpheme/lang \
#####  $datadir/test \
#####  $srcdir/decode_test_morpheme_1stPass \
#####  $srcdir/decode_test_morpheme_2ndRescoring  || exit 1;
#####
#####local/wer_morph-to-word.sh $srcdir/decode_test_morpheme_2ndRescoring || exit 1;
##############################decode morpheme with rescoring --- End 


################################ use the whole morphem LM
################################ build HCLG.fst using large LM G.fst
#####utils/mkgraph.sh $opt data/graph_morpheme/lang $srcdir $srcdir/graph_morpheme || exit 1;
#####
################################ decode morpheme of Big LM by steps/decode.sh"
#####$decoder_word --cmd "$decode_cmd" --nj $nj $srcdir/graph_morpheme $datadir/test $srcdir/decode_test_morpheme_whole || exit 1;
#####
#####local/wer_morph-to-word.sh $srcdir/decode_test_morpheme_whole || exit 1;
