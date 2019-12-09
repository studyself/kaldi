MLDG-Decoder for THUYG-20
================================
This is the source code for our paper: Improving Uyghur ASR systems with decoders using morpheme-based LMs. 

Follow Kaldi's guide to build the toolkit. 
The two morpheme-based decoders have been added into src/bin and src/bin/Makefile.
1. src/bin/latgen-biglm-faster-mapped.cc
2. src/bin/MLDG-Decoder.cc
3. They will be built while the toolkit is built. 
4. They are the same in contents, but the names are different.
5. latgen-biglm-faster-mapped is the name used in THUYG-20's original recipes.
6. MLDG-Decoder is the name used in our paper.

THUYG-20 Data:
--------------------------
It's free for download at: https://openslr.org/22/



Original wrk on THUYG-20 by Dong Wang:
------------------------------------
https://github.com/wangdong99/kaldi
1. The morpheme-based decoder is missing there.
2. The morpheme-based decoder cann't be found in Kaldi's source code: https://github.com/kaldi-asr/kaldi/tree/master/src/bin




THUYG-20 recipes:
------------------------------------
You can run the scripts in egs/thuyg20 to reproduce our experimental results.
