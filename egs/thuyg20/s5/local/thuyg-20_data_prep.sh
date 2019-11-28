#!/bin/bash
#Copyright 2016  Tsinghua University (Author: Dong Wang, Xuewei Zhang).  Apache 2.0.

#This script pepares the data directory for thuyg20 recipe. 
#It reads the corpus and get wav.scp and transcriptions.

dir=$1
corpus_dir=$2


cd $dir

echo "creating data/{train,cv,test}"
mkdir -p data/{train,cv,test}

#create wav.scp, utt2spk.scp, spk2utt.scp, text
for x in train cv test; do
  echo "cleaning data/$x"
  cd $dir/data/$x
  rm -rf wav.scp utt2spk spk2utt text
  echo "preparing scps and text in data/$x"
  cat $corpus_dir/trans/trans.$x | sort -u | while read line
  do
    nn=`echo "$line" | cut -d / -f 3 | awk -F" " '{print $1}' | sed 's/.wav//g'`
	xx=`echo "$line" | cut -d / -f 3 | awk 'BEGIN{FS=OFS=" "} {for(i=2;i<=NF;i++) print $i}'`
    echo $nn $corpus_dir/data/$nn.wav >> wav.scp
	echo $nn $nn >> utt2spk
	echo $nn $nn >> spk2utt
	echo $nn $xx >> text

  done
done


