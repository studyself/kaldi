#!/bin/bash
#Copyright 2016  Tsinghua University (Author: Dong Wang, Xuewei Zhang).  Apache 2.0.

#run from ../..
#DNN training, both xent and MPE


. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ./path.sh ## Source the tools/utils (import the queue.pl)

stage=3
nTrn=32
nDcd=32
nDcdM=7
nDcdMW=1

. utils/parse_options.sh || exit 1;

gmmdir=$1
alidir=$2
alidir_cv=$3

#generate fbanks
if [ $stage -le 0 ]; then
  rm -rf data/fbank && mkdir -p data/fbank &&  cp -R data/{train,cv,test} data/fbank || exit 1;
  cp -R data/test data/fbank/testM || exit 1;
fi

sleep 1s

if [ $stage -le 0 ]; then
  echo "DNN training: stage 0: feature generation"
  for x in train cv; do
    echo "producing fbank for $x"
    #fbank generation
    steps/make_fbank.sh --nj $nTrn --cmd "$train_cmd" data/fbank/$x exp/make_fbank/$x fbank/$x || exit 1
    #compute cmvn
    steps/compute_cmvn_stats.sh data/fbank/$x exp/fbank_cmvn/$x fbank/$x/_cmvn || exit 1
  done
fi

#generate fbanks
if [ $stage -le 0 ]; then
  echo "DNN training: stage 0: feature generation"
  for x in test; do
    echo "producing fbank for $x"
    #fbank generation
    steps/make_fbank.sh --nj $nDcd --cmd "$train_cmd" data/fbank/$x exp/make_fbank/$x fbank/$x || exit 1
    #compute cmvn
    steps/compute_cmvn_stats.sh data/fbank/$x exp/fbank_cmvn/$x fbank/$x/_cmvn || exit 1
  done
fi

#generate fbanks
if [ $stage -le 0 ]; then
  echo "DNN training: stage 0: feature generation"
  for x in testM; do
    echo "producing fbank for $x"
    #fbank generation
    steps/make_fbank.sh --nj $nDcdM --cmd "$train_cmd" data/fbank/$x exp/make_fbank/$x fbank/$x || exit 1
    #compute cmvn
    steps/compute_cmvn_stats.sh data/fbank/$x exp/fbank_cmvn/$x fbank/$x/_cmvn || exit 1
  done
fi
# sleep 1m


 #xEnt training
 if [ $stage -le 1 ]; then
   outdir=exp/tri2b_dnn_7Ls_2048_tri2b_4200_50000
    #NN training
    (tail --pid=$$ -F $outdir/log/train_nnet.log 2>/dev/null)& # forward log
    $cuda_cmd $outdir/log/train_nnet.log \
      steps/nnet/train.sh --copy_feats false --cmvn-opts "--norm-means=true --norm-vars=false" --hid-layers 7 --hid-dim 2048 \
  	  --learn-rate 0.008 data/fbank/train data/fbank/cv data/lang $alidir $alidir_cv $outdir || exit 1;
 
   #Decode (reuse HCLG graph)
#     (
#       steps/nnet/decode.sh --nj $nDcd --cmd "$decode_cmd" --srcdir $outdir --config conf/decode_dnn.config --acwt 0.1 \
#         $gmmdir/graph_word data/fbank/test $outdir/decode_test_word || exit 1;
#     )&
 
#    ( ### morpheme decoding with rescoring
#     steps/nnet/decode.sh --nj $nDcdM --cmd "$decode_cmd" --srcdir $outdir --config conf/decode_dnn.config --acwt 0.1  \
#       $gmmdir/graph_morpheme_s data/fbank/test $outdir/decode_test_morpheme_s_1stPass || exit 1;
#    local/wer_morph-to-word.sh $outdir/decode_test_morpheme_s_1stPass  || exit 1;
#     
#     # second pass, rescoring with a large language model
#     steps/lmrescore.sh --cmd "$decode_cmd" \
#       data/graph_morpheme_s/lang \
#       data/graph_morpheme/lang \
#       data/fbank/test \
#       $outdir/decode_test_morpheme_s_1stPass  $outdir/decode_test_morpheme_2ndRescoring   || exit 1;
#    local/wer_morph-to-word.sh $outdir/decode_test_morpheme_2ndRescoring  || exit 1;
#    )&
 
#    (
#     local/nnet/decode_biglm.sh --nj $nDcdM --cmd "$decode_cmd" --srcdir $outdir --config conf/decode_dnn.config --acwt 0.1 \
#       $gmmdir/graph_morpheme_s data/graph_morpheme_s/lang/G.fst data/graph_morpheme/lang/G.fst \
#  	 data/fbank/test $outdir/decode_test_morpheme || exit 1;
#     local/wer_morph-to-word.sh $outdir/decode_test_morpheme || exit 1;
#    )&

#     ( ### morpheme decoding with the Big LM as a whole 
#      ####utils/mkgraph.sh $opt data/graph_morpheme/lang $srcdir $srcdir/graph_morpheme || exit 1;
##       utils/mkgraph.sh $opt data/graph_morpheme/lang $gmmdir $gmmdir/graph_morpheme || exit 1;
#       steps/nnet/decode.sh --nj $nDcdMW --cmd "$decode_cmd" --nnet $outdir/final.nnet --config conf/decode_dnn.config --acwt 0.1 \
#         $gmmdir/graph_morpheme data/fbank/test $outdir/decode_test_morpheme_whole_xent || exit 1;
#      local/wer_morph-to-word.sh $outdir/decode_test_morpheme_whole_xent || exit 1;
#      )&
 fi
 
 #####sleep 150m
 
  if [ $stage -le 2 ]; then
  #MPE training
  srcdir=exp/tri2b_dnn_7Ls_2048_tri2b_4200_50000
  acwt=0.1
    # generate lattices and alignments
    steps/nnet/align.sh --nj $nTrn --cmd "$train_cmd" \
      data/fbank/train data/lang $srcdir ${srcdir}_ali || exit 1;
    steps/nnet/make_denlats.sh --nj $nTrn --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt $acwt \
      data/fbank/train data/lang $srcdir ${srcdir}_denlats || exit 1;
  fi
 
# sleep 150m
 
  if [ $stage -le 3 ]; then
    nDcd=32
    nDcdM=3 
    srcdir=exp/tri2b_dnn_7Ls_2048_tri2b_4200_50000
   # srcdir=exp/tri2b_dnn_6Ls_1024
    acwt=0.1
    outdir=exp/tri2b_dnn_mpe_7Ls_2048_tri2b_4200_50000
    # outdir=exp/tri2b_dnn_mpe_6Ls_1024

    #Re-train the DNN by 3 iteration of MPE
#    steps/nnet/train_mpe.sh --cmd "$cuda_cmd" --num-iters 100 --acwt $acwt --do-smbr false  \
#      data/fbank/train data/lang $srcdir ${srcdir}_ali ${srcdir}_denlats $outdir || exit 1;

    ###  #Decode (reuse HCLG graph)
    for ITER in 1 10 20 30 40 50 60 70 80 90 100; do
#     ( ### word decoding
#      steps/nnet/decode.sh --nj $nDcd --cmd "$decode_cmd" --nnet $outdir/${ITER}.nnet --config conf/decode_dnn.config --acwt $acwt \
#        $gmmdir/graph_word data/fbank/test $outdir/decode_test_word_it${ITER} || exit 1;
#     )&
   
##     ( ### morpheme decoding with rescoring
##      steps/nnet/decode.sh --nj $nDcdM --cmd "$decode_cmd" --nnet $outdir/${ITER}.nnet --config conf/decode_dnn.config --acwt $acwt \
##        $gmmdir/graph_morpheme_s data/fbank/test $outdir/decode_test_morpheme_s_1stPass_it${ITER} || exit 1;
##     local/wer_morph-to-word.sh $outdir/decode_test_morpheme_s_1stPass_it${ITER}  || exit 1;
##      
##      ###### second pass, rescoring with a large language model
##      steps/lmrescore.sh --cmd "$decode_cmd" \
##        data/graph_morpheme_s/lang \
##        data/graph_morpheme/lang \
##        data/fbank/test \
##        $outdir/decode_test_morpheme_s_1stPass_it${ITER}  $outdir/decode_test_morpheme_2ndRescoring_it${ITER}   || exit 1;
##     local/wer_morph-to-word.sh $outdir/decode_test_morpheme_2ndRescoring_it${ITER}  || exit 1;
##    )&
  
       ( ### Biglm used, Big G - Small Gp = F, HCLG composing F get the result
        local/nnet/decode_biglm.sh --nj $nDcdM --cmd "$decode_cmd" --nnet $outdir/${ITER}.nnet --config conf/decode_dnn.config --acwt $acwt \
          $gmmdir/graph_morpheme_s data/graph_morpheme_s/lang/G.fst data/graph_morpheme/lang/G.fst \
         data/fbank/testM $outdir/decode_test_morpheme_largeMem_it${ITER} || exit 1;
        local/wer_morph-to-word.sh $outdir/decode_test_morpheme_largeMem_it${ITER} || exit 1;
        )&
  
#     ( ### morpheme decoding with the Big LM as a whole 
# #      ####utils/mkgraph.sh $opt data/graph_morpheme/lang $srcdir $srcdir/graph_morpheme || exit 1;
# #      utils/mkgraph.sh $opt data/graph_morpheme/lang $gmmdir $gmmdir/graph_morpheme || exit 1;
#       steps/nnet/decode.sh --nj $nDcdMW --cmd "$decode_cmd" --nnet $outdir/${ITER}.nnet --config conf/decode_dnn.config --acwt $acwt \
#         $gmmdir/graph_morpheme data/fbank/test $outdir/decode_test_morpheme_whole_it${ITER} || exit 1;
#      local/wer_morph-to-word.sh $outdir/decode_test_morpheme_whole_it${ITER}  || exit 1;
#      )&
done
fi
