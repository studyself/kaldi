#!/bin/bash
#Copyright 2016  Tsinghua University (Author: Dong Wang, Xuewei Zhang).  Apache 2.0.

#Conducts experiments of noise training  

dwntest=false
stdtest=false
stage=0
nj=8

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ./path.sh ## Source the tools/utils (import the queue.pl)
. utils/parse_options.sh || exit 1;

thuyg=$1
gmmdir=$2
alidir=$3
alidir_cv=$4

#generate noisy data. We focuse on the 0db training and 0db test condition.
#For training set, generate noisy data with SNR mean=0, variance=10, with three noise types mixed together.  
#For cv, generate noisy data with SNR mean=0, variance=0, with three niose types mixed together.
#For test, either use the standard test set (stdtest=true) or randomly generated data (stdtest=false)

if [ $stage -le 0 ]; then
   #generat noise.scp
   mkdir -p data/train_noise/noise && \
   awk '{print $1 " '$thuyg'/resource/noise/"$2}' $thuyg/resource/noise/noise.scp >  data/train_noise/noise/noise.scp || exit 1
   echo "generate training data..."
   noise_scp=data/train_noise/noise/noise.scp
   noise_prior="10.0,10.0,10.0,10.0" #define noise type to sample. [S_clean, S_white, S_car, S_cafe]
 
   noise_level=0 #0db condition
   sigma0=10 #some random in SNR
   seed=32
   verbose=0
   wavdir=wav/train_noise/train 
   rm -rf data/train_noise/train && mkdir -p data/train_noise/train || exit 1
   cp data/fbank/train/{spk2utt,utt2spk,text} data/train_noise/train || exit 1
   mkdir -p $wavdir && awk '{print $1 " '$wavdir'/"$1".wav"}' data/fbank/train/wav.scp > data/train_noise/train/wav.scp || exit 1

   mkdir -p exp/train_noise/gendata 
   split_scps=""
   for n in $(seq $nj); do
      split_scps="$split_scps exp/train_noise/gendata/train_split_${n}.scp"
   done
   utils/split_scp.pl data/fbank/train/wav.scp  $split_scps || exit 1
   $train_cmd JOB=1:$nj exp/train_noise/gendata/add_noise_train.JOB.log \
     local/nnet/add-noise-mod.py --noise-level $noise_level \
       --sigma0 $sigma0 --seed $seed --verbose $verbose \
       --noise-prior $noise_prior --noise-src $noise_scp \
       --wav-src exp/train_noise/gendata/train_split_JOB.scp --wavdir $wavdir \
       || exit 1

   steps/make_fbank.sh --nj $nj --cmd "$train_cmd"  \
     data/train_noise/train exp/train_noise/gendata fbank/train_noise/train || exit 1
   steps/compute_cmvn_stats.sh data/train_noise/train exp/train_noise/cmvn \
     fbank/train_noise/train/_cmvn || exit 1
   #genreate cv data. The 0db condition is produced.  Multiple noise types mixed together.
   echo "noise taining: generating cv data..."
   wavdir=wav/train_noise/cv/0db
   sigma0=0 #no random in SNR
   rm -rf data/train_noise/cv/0db && mkdir -p data/train_noise/cv/0db && \
   cp -L data/fbank/cv/{spk2utt,utt2spk,text} data/train_noise/cv/0db || exit 1
   mkdir -p $wavdir && awk '{print $1 " '$wavdir'/"$1".wav"}' data/fbank/cv/wav.scp > data/train_noise/cv/0db/wav.scp || exit 1

   split_scps=""
   for n in $(seq $nj); do
      split_scps="$split_scps exp/train_noise/gendata/cv_split_${n}.scp"
   done
   utils/split_scp.pl data/fbank/cv/wav.scp  $split_scps || exit 1

   $train_cmd JOB=1:$nj exp/train_noise/gendata/add_noise_cv.JOB.log \
     local/nnet/add-noise-mod.py --noise-level $noise_level \
       --sigma0 $sigma0 --seed $seed --verbose $verbose \
       --noise-prior $noise_prior --noise-src $noise_scp \
       --wav-src exp/train_noise/gendata/cv_split_JOB.scp --wavdir $wavdir \
       || exit 1
   steps/make_fbank.sh --nj $nj --cmd "$train_cmd"  \
     data/train_noise/cv/0db exp/train_noise/gendata fbank/train_nosie/cv || exit 1
   steps/compute_cmvn_stats.sh data/train_noise/cv/0db exp/train_noise/cmvn \
     fbank/train_noise/cv/_cmvn || exit 1
   #generate test data. Note that if you want to compare with the standard results, set stdtest=true
   echo "DAE: generating test data..."
   if [ $stdtest = true ]; then
     #download noisy wav if use the standard test data
     echo "using standard test data"
     if [ $dwntest = true ];then
       echo "downloading the noisy test data from openslr..."
       (
         wget http://www.openslr.org/resources/19/test_noise.tgz || exit 1
         tar xvf test_noise.tgz || exit 1
       )
     fi
     #generate fbank
     for x in car white cafe; do
       echo "producing fbanks for $x"
       mkdir -p data/train_noise/test/0db/$x && \
       cp -L data/fbank/test/{spk2utt,utt2spk,text} data/train_noise/test/0db/$x && \
       awk '{print $1 " wav/test_noise/wav/0db/'$x'/"$1".wav"}' data/fbank/test/wav.scp > data/train_noise/test/0db/$x/wav.scp || exit 1
       steps/make_fbank.sh --nj $nj --cmd "$train_cmd"  \
         data/train_noise/test/0db/$x exp/train_noise/gendata fbank/train_noise/test/0db/$x || exit 1
     done

   else
     #generate test data randomly
     sigma0=0 #no random in SNR
     noise_level=0
     echo "generating noisy test data randomly"
     for x in car white cafe; do
       echo "generating noisy wav for $x"

       case $x in
         car)
            noise_prior="0.0,0.0,10.0,0.0" 
            ;;
         white)
            noise_prior="0.0,10.0,0.0,0.0" 
            ;;
         cafe)
            noise_prior="0.0,0.0,0.0,10.0" 
            ;;
       esac

       wavdir=wav/test_noise/0db/$x 
       rm -rf data/train_noise/test/0db/$x && mkdir -p data/train_noise/test/0db/$x && \
       cp -L data/fbank/test/{spk2utt,utt2spk,text} data/train_noise/test/0db/$x || exit 1
       mkdir -p $wavdir && awk '{print $1 " '$wavdir'/"$1".wav"}' data/fbank/test/wav.scp > data/train_noise/test/0db/$x/wav.scp || exit 1

       split_scps=""
       for n in $(seq $nj); do
         split_scps="$split_scps exp/train_noise/gendata/test_split_${n}.scp"
       done
       utils/split_scp.pl data/fbank/test/wav.scp  $split_scps || exit 1


       $train_cmd JOB=1:$nj exp/train_noise/gendata/add_noise_dev.JOB.log \
         local/nnet/add-noise-mod.py --noise-level $noise_level \
           --sigma0 $sigma0 --seed $seed --verbose $verbose \
           --noise-prior $noise_prior --noise-src $noise_scp \
           --wav-src exp/train_noise/gendata/test_split_JOB.scp --wavdir $wavdir \
           || exit 1

       echo "producing fbanks for test data $x"
       steps/make_fbank.sh --nj $nj --cmd "$train_cmd"  \
         data/train_noise/test/0db/$x exp/train_noise/gendata fbank/train_noise/test/0db/$x || exit 1
	   echo "generating cmvn for test data $x"
	   steps/compute_cmvn_stats.sh data/train_noise/test/0db/$x exp/train_noise/cmvn \
		 fbank/train_noise/test/0db/$x/_cmvn || exit 1
     done
   fi
fi

#noise training
if [ $stage -le 1 ]; then
  #noise training  using data with mixed noise
  outdir=exp/tri4b_dnn_0_10_white_car_cafe_clean && mkdir -p exp/tri4b_dnn_0_10_white_car_cafe_clean || exit 1

  $cuda_cmd exp/tri4b_dnn_0_10_white_car_cafe_clean/log/train_nnet.log \
  steps/nnet/train.sh --copy-feats false --cmvn-opts "--norm-means=true --norm-vars=false" --hid-layers 4 --hid-dim 1024 \
      --learn-rate 0.008 data/train_noise/train data/train_noise/cv/0db data/lang $alidir $alidir_cv $outdir || exit 1; 
fi
#decoding 
if [ $stage -le 2 ]; then
   for x in car cafe white; do
    #decode word 
    (
      steps/nnet/decode.sh --cmd "$decode_cmd" --nj $nj --srcdir exp/tri4b_dnn \
         $gmmdir/graph_word data/train_noise/test/0db/$x exp/tri4b_dnn/decode_word_0db/$x || exit 1;
    )&

	(   
	  steps/nnet/decode.sh --cmd "$decode_cmd" --nj $nj --srcdir exp/tri4b_dnn_0_10_white_car_cafe_clean \
         $gmmdir/graph_word data/train_noise/test/0db/$x \
		 exp/tri4b_dnn_0_10_white_car_cafe_clean/decode_word_0db/$x || exit 1;
	)&  

   #decode morpheme
   ( 
      local/nnet/decode_biglm.sh  --cmd "$decode_cmd" --nj $nj --srcdir exp/tri4b_dnn \
       --config conf/decode_dnn.config --acwt 0.1 \
	    $gmmdir/graph_morpheme_s data/graph_morpheme_s/lang/G.fst data/graph_morpheme/lang/G.fst \
	    data/train_noise/test/0db/$x exp/tri4b_dnn/decode_morpheme_0db/$x || exit 1;
 	  local/wer_morph-to-word.sh  exp/tri4b_dnn/decode_morpheme_0db/$x || exit 1;
   )&
    
   (
      local/nnet/decode_biglm.sh  --cmd "$decode_cmd" --nj $nj --srcdir exp/tri4b_dnn_0_10_white_car_cafe_clean \
       --config conf/decode_dnn.config --acwt 0.1 \
       $gmmdir/graph_morpheme_s data/graph_morpheme_s/lang/G.fst data/graph_morpheme/lang/G.fst \  
	   data/train_noise/test/0db/$x exp/tri4b_dnn_0_10_white_car_cafe_clean/decode_morpheme_0db/$x || exit 1;
      local/wer_morph-to-word.sh  exp/tri4b_dnn_0_10_white_car_cafe_clean/decode_morpheme_0db/$x || exit 1; 
  )&	    
		 
   done
fi

