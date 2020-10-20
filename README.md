MLDG-Decoder for THUYG-20
================================
This is the source code for our paper: Improving Uyghur ASR systems with decoders using morpheme-based LMs. 

Follow Kaldi's guide to build the toolkit. 
The morpheme-based decoder has been added into src/bin and src/bin/Makefile.
1. src/bin/MLDG-Decoder.cc
2. It will be built while the toolkit is built. 
3. MLDG-Decoder is used in decode_biglm.sh.

THUYG-20 Data:
--------------------------
It's free for download at: https://openslr.org/22/



Original wrk on THUYG-20 by Dong Wang:
------------------------------------
https://github.com/wangdong99/kaldi
1. latgen-biglm-faster-mapped is used to achieve the lowest WER
2. source code of latgen-biglm-faster-mapped is missing there
2. A Biglm wrapper for DNN-HMM systems cann't be found in Kaldi's source code neither: https://github.com/kaldi-asr/kaldi/tree/master/src/bin

THUYG-20 recipes:
------------------------------------
You can run the scripts in egs/thuyg20 to reproduce our experimental results:
https://github.com/studyself/kaldi/tree/master/egs/thuyg20/s5
