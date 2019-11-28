#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.
. ./path.sh

H=`pwd`  #exp home
nTrn=32   ### jobs num for train
nDcd=32   ### jobs num for decode word
nDcdM=8   ### jobs num for decode morpheme
nDcdMW=1  ### jobs num for decode morpheme with whole LM
#####nTrn=16      #parallel jobs for train
#####nDcd=4      #parallel jobs

stage=11

thuyg=/qkaldi/kaldi/egs/thuyg20/thuyg20Data
#####thuyg=/home/qiu/uyghurExp/thuyg20Data
###thuyg=/home/qiu/experimentSource/thuyg20Data
#thuyg=/home/quinnqiu/UyghurKaldi/thuyg20Data
#thuyg=/work3/zxw/thuyg20-openslr
nvidia-smi -c 3

if [ $stage -le 0 ]; then
echo "download thuyg20 corpus"
#corpus and trans directory
#you can obtain the database by uncommting the following lines
#( cd $thuyg
#     echo "downloading THUYG20 at $PWD ..."
#     wget http://www.openslr.org/resources/19/data_thuyg20.tgz
#     wget http://www.openslr.org/resources/19/resource.tgz
#     tar xvf data_thuyg20.tgz && tar xvf resource.tgz
#)
fi

if [ $stage -le 3 ]; then
#data preparation
#generate text, wav.scp, utt2pk, spk2utt
local/thuyg-20_data_prep.sh $H $thuyg/data_thuyg20 || exit 1;
fi


if [ $stage -le 3 ]; then
#produce MFCC features
rm -rf data/mfcc && mkdir -p data/mfcc &&  cp -R data/{train,cv,test} data/mfcc || exit 1;
cp -R data/test data/mfcc/testM || exit 1;
for x in train cv; do
   #make  mfcc
   steps/make_mfcc.sh --nj $nTrn --cmd "$train_cmd" data/mfcc/$x exp/make_mfcc/$x mfcc/$x || exit 1;
   #compute cmvn
   steps/compute_cmvn_stats.sh data/mfcc/$x exp/mfcc_cmvn/$x mfcc/$x/_cmvn || exit 1;
done

#####
for x in test; do
   #make  mfcc
   steps/make_mfcc.sh --nj $nDcd --cmd "$train_cmd" data/mfcc/$x exp/make_mfcc/$x mfcc/$x || exit 1;
   #compute cmvn
   steps/compute_cmvn_stats.sh data/mfcc/$x exp/mfcc_cmvn/$x mfcc/$x/_cmvn || exit 1;
done

for x in testM; do
   #make  mfcc
   steps/make_mfcc.sh --nj $nDcd --cmd "$train_cmd" data/mfcc/$x exp/make_mfcc/$x mfcc/$x || exit 1;
   #compute cmvn
   steps/compute_cmvn_stats.sh data/mfcc/$x exp/mfcc_cmvn/$x mfcc/$x/_cmvn || exit 1;
done
fi

if [ $stage -le 3 ]; then
###########prepare language stuff
###########build a large lexicon that invovles words in both the training and decoding.
 (
  echo "make word graph ..."
  cd $H; mkdir -p data/{dict,lang,graph} && \
  cp $thuyg/resource/dict/{extra_questions.txt,nonsilence_phones.txt,optional_silence.txt,silence_phones.txt} data/dict && \
  cat $thuyg/resource/dict/lexicon.txt | sort -u > data/dict/lexicon.txt || exit 1;
  utils/prepare_lang.sh --position_dependent_phones false data/dict SIL data/local/lang data/lang || exit 1;
  cp $thuyg/data_thuyg20/lm_word/vword.3gram.th1e-7.gz data/graph || exit 1;
  utils/format_lm.sh data/lang data/graph/vword.3gram.th1e-7.gz $thuyg/data_thuyg20/lm_word/lexicon.txt data/graph/lang || exit 1;

 )

######make big morpheme graph
#morpheme LM is too large to generate HCLG.fst beacause of limited memory. Fist, use the large LM to produce G.fst. Then, clip the large to make probability  more than e-5 and use the new LM to produce G.fst and HCLG.fst. Finally, combine HCLG.fst,G.fst from the new LM and G.fst from large LM to decode.
 (
  echo "make big morpheme graph ..."
  cd $H; mkdir -p data/{dict_morpheme,graph_morpheme,lang_morpheme} && \
  cp $thuyg/resource/dict/{extra_questions.txt,nonsilence_phones.txt,optional_silence.txt,silence_phones.txt} data/dict_morpheme  && \
  cat $thuyg/data_thuyg20/lm_morpheme/uyghur-pseudo-morpheme.lex | grep -v '<s>' | grep -v '</s>' | sort -u > data/dict_morpheme/lexicon.txt \
  && echo "SIL sil" >> data/dict_morpheme/lexicon.txt  || exit 1;
  utils/prepare_lang.sh --position_dependent_phones false data/dict_morpheme SIL data/local/lang_morpheme data/lang_morpheme || exit 1;
  cp $thuyg/data_thuyg20/lm_morpheme/uyghur-pseudo-morpheme.arpa4-org.gz data/graph_morpheme || exit 1;
  utils/format_lm.sh data/lang_morpheme data/graph_morpheme/uyghur-pseudo-morpheme.arpa4-org.gz \
    $thuyg/data_thuyg20/lm_morpheme/uyghur-pseudo-morpheme.lex data/graph_morpheme/lang  || exit 1;
 )


#make_small_morpheme_graph
 (
  echo "make small morpheme graph ..."
  cd $H; mkdir -p data/{dict_morpheme_s,graph_morpheme_s,lang_morpheme_s} && \
  cp $thuyg/resource/dict/{extra_questions.txt,nonsilence_phones.txt,optional_silence.txt,silence_phones.txt} data/dict_morpheme_s  && \
  cat $thuyg/data_thuyg20/lm_morpheme/uyghur-pseudo-morpheme.lex | grep -v '<s>' | grep -v '</s>' | sort -u > data/dict_morpheme_s/lexicon.txt \
  && echo "SIL sil" >> data/dict_morpheme_s/lexicon.txt  || exit 1;
  utils/prepare_lang.sh --position_dependent_phones false data/dict_morpheme_s SIL data/local/lang_morpheme_s data/lang_morpheme_s || exit 1;
  cp $thuyg/data_thuyg20/lm_morpheme/uyghur-pseudo-morpheme.arpa4.1e-5.gz data/graph_morpheme_s || exit 1;
  utils/format_lm.sh data/lang_morpheme_s data/graph_morpheme_s/uyghur-pseudo-morpheme.arpa4.1e-5.gz \
    $thuyg/data_thuyg20/lm_morpheme/uyghur-pseudo-morpheme.lex data/graph_morpheme_s/lang  || exit 1;
)
fi

if [ $stage -le 3 ]; then
#monophone
steps/train_mono.sh --boost-silence 1.25 --nj $nTrn --cmd "$train_cmd" data/mfcc/train data/lang exp/mono || exit 1;

#test monophone model
local/thuyg-20_decode_rescore.sh --mono true --nj $nDcd "steps/decode.sh" "steps/decode_biglm.sh" exp/mono data/mfcc &

#monophone_ali
steps/align_si.sh --boost-silence 1.25 --nj $nTrn --cmd "$train_cmd" data/mfcc/train data/lang exp/mono exp/mono_ali || exit 1;
fi

if [ $stage -le 5 ]; then
######triphone
steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" 4000 30000 data/mfcc/train data/lang exp/mono_ali exp/tri1 || exit 1;

#################test tri1 model
#####local/thuyg-20_decode_rescore.sh --nj $nDcd "steps/decode.sh" "steps/decode_biglm.sh" exp/tri1_leavesL data/mfcc &
local/thuyg-20_decode_rescore.sh --nj $nDcd "steps/decode.sh" "steps/decode_biglm.sh" exp/tri1 data/mfcc &

######triphone_ali
steps/align_si.sh --nj $nTrn --cmd "$train_cmd" data/mfcc/train data/lang exp/tri1 exp/tri1_ali || exit 1;
fi

if [ $stage -le 6 ]; then
#############lda_mllt
# steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" 4500 35000 data/mfcc/train data/lang exp/tri1_ali exp/tri2b_xiemen4 || exit 1;

steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" 4200 50000 data/mfcc/train data/lang exp/tri1_ali exp/tri2b_4500_35000_5
#####
#test tri2b model
# local/thuyg-20_decode_rescore.sh --nj $nDcd "steps/decode.sh" "steps/decode_biglm.sh" exp/tri2b_xiemen4 data/mfcc &
local/thuyg-20_decode_rescore.sh --nj $nDcd "steps/decode.sh" "steps/decode_biglm.sh" exp/tri2b_4500_35000_5 data/mfcc &

#####################local/thuyg-20_decode_rescore.sh --nj $nDcd "steps/decode.sh" "steps/decode_biglm.sh" exp/tri2b_leavesL data/mfcc &

###lda_mllt_ali
steps/align_si.sh  --nj $nTrn --cmd "$train_cmd" --use-graphs true data/mfcc/train data/lang exp/tri2b exp/tri2b_ali || exit 1;
fi

if [ $stage -le 7 ]; then
#sat
steps/train_sat.sh --cmd "$train_cmd" 4200 40000 data/mfcc/train data/lang exp/tri2b_ali exp/tri3b || exit 1;

echo "*****************************************************************************************************************************"
echo "step15: sat Finished"
echo "*****************************************************************************************************************************"

#test tri3b model
local/thuyg-20_decode.sh --nj $nDcd "steps/decode_fmllr.sh" "steps/decode_biglm.sh" exp/tri3b data/mfcc &

echo "*****************************************************************************************************************************"
echo "step16: test tri3b model Finished"
echo "*****************************************************************************************************************************"

#sat_ali
steps/align_fmllr.sh --nj $nDcd --cmd "$train_cmd" data/mfcc/train data/lang exp/tri3b exp/tri3b_ali || exit 1;

echo "*****************************************************************************************************************************"
echo "step17: sat ali Finished"
echo "*****************************************************************************************************************************"
fi

#########
if [ $stage -le 8 ]; then
#quick
steps/train_quick.sh --cmd "$train_cmd" 4200 50000 data/mfcc/train data/lang exp/tri3b_ali exp/tri4b || exit 1;

echo "*****************************************************************************************************************************"
echo "step18: quick Finished"
echo "*****************************************************************************************************************************"

#test tri4b model
local/thuyg-20_decode.sh --nj $nDcd "steps/decode_fmllr.sh" "steps/decode_biglm.sh" exp/tri4b data/mfcc &

echo "*****************************************************************************************************************************"
echo "step19: test tri4b model Finished"
echo "*****************************************************************************************************************************"

#quick_ali
steps/align_fmllr.sh --nj $nDcd --cmd "$train_cmd" data/mfcc/train data/lang exp/tri4b exp/tri4b_ali || exit 1;

echo "*****************************************************************************************************************************"
echo "step20: quick ali Finished"
echo "*****************************************************************************************************************************"
#####
fi

if [ $stage -le 9 ]; then
#############lda_mllt
# steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" 4500 35000 data/mfcc/train data/lang exp/tri1_ali exp/tri2b_xiemen4 || exit 1;

steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" 4200 50000 data/mfcc/train data/lang exp/tri1_ali exp/tri2b_4200_50000

#test tri2b model
# local/thuyg-20_decode_rescore.sh --nj $nDcd "steps/decode.sh" "steps/decode_biglm.sh" exp/tri2b_xiemen4 data/mfcc &
local/thuyg-20_decode_rescore.sh --nj $nDcd "steps/decode.sh" "steps/decode_biglm.sh" exp/tri2b_4200_50000 data/mfcc &

#####################local/thuyg-20_decode_rescore.sh --nj $nDcd "steps/decode.sh" "steps/decode_biglm.sh" exp/tri2b_leavesL data/mfcc &

###lda_mllt_ali
steps/align_si.sh  --nj $nTrn --cmd "$train_cmd" --use-graphs true data/mfcc/train data/lang exp/tri2b_4200_50000 exp/tri2b_4200_50000_ali || exit 1;
fi

if [ $stage -le 10 ]; then
## #lda_mllt_ali
## steps/align_si.sh  --nj $nTrn --cmd "$train_cmd" --use-graphs true data/mfcc/train data/lang exp/tri2b_6Ls exp/tri2b_6Ls_ali || exit 1;

#quick_ali_cv
steps/align_fmllr.sh --nj $nTrn --cmd "$train_cmd" data/mfcc/cv data/lang exp/tri2b_4200_50000 exp/tri2b_4200_50000_ali_cv || exit 1;

#steps/align_si.sh  --nj $nTrn --cmd "$train_cmd" --use-graphs true data/mfcc/train data/lang exp/tri2b_4200_50000 exp/tri2b_ali || exit 1;

## 
## #quick_ali_cv
## steps/align_fmllr.sh --nj $nTrn --cmd "$train_cmd" data/mfcc/cv data/lang exp/tri2b_6Ls exp/tri2b_6Ls_ali_cv || exit 1;

#quick_ali_cv
## steps/align_fmllr.sh --nj $nTrn --cmd "$train_cmd" data/mfcc/cv data/lang exp/tri2b_4500_35000_5 exp/tri2b_ali_cv || exit 1;

# steps/align_si.sh  --nj $nTrn --cmd "$train_cmd" --use-graphs true data/mfcc/cv data/lang exp/tri2b_4500_35000_5 exp/tri2b_ali_cv || exit 1;
fi

if [ $stage -le 11 ]; then
#train dnn model
#####local/nnet/run_dnn_it5.sh --stage 0 --nj $nDcd  exp/tri2b exp/tri2b_ali exp/tri2b_ali_cv || exit 1;
nTrn=32   ### jobs num for train
nDcd=32   ### jobs num for decode word
nDcdM=32   ### jobs num for decode morpheme
nDcdMW=15  ### jobs num for decode morpheme with whole LM
## local/nnet/run_dnn_speedup_6Ls.sh --stage 6 --nTrn $nTrn --nDcd $nDcd --nDcdM $nDcdM --nDcdMW $nDcdMW  exp/tri2b exp/tri2b_ali exp/tri2b_ali_cv || exit 1;

## local/nnet/run_dnn_speedup_6Ls.sh --stage 1  --nTrn $nTrn --nDcd $nDcd --nDcdM $nDcdM --nDcdMW $nDcdMW  exp/tri2b_4500_35000_5 exp/tri2b_ali exp/tri2b_ali_cv || exit 1;

local/nnet/run_dnn_speedup.sh --stage 3  --nTrn $nTrn --nDcd $nDcd --nDcdM $nDcdM --nDcdMW $nDcdMW  exp/tri2b_4200_50000 exp/tri2b_4200_50000_ali exp/tri2b_4200_50000_ali_cv || exit 1;
fi

#####echo "*****************************************************************************************************************************"
#####echo "step22: train dnn model Finished"
#####echo "*****************************************************************************************************************************"
#####
#noise training dnn model
#python2.6 or above is required for noisy data generation.
#To speed up the process, pyximport for python is recommeded.
#In order to use the standard noisy test data, set "--stdtest true" and "--dwntest true"
#local/nnet/run_dnn_noise_training.sh --stage 0  --stdtest false --dwntest false $thuyg exp/tri4b exp/tri4b_ali exp/tri4b_ali_cv ||  exit 1;
