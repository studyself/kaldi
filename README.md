MLDG-Decoder for THUYG-20
================================
This is the source code for our paper: Improving Uyghur ASR systems with decoders using morpheme-based LMs. 

Follow Kaldi's guide to build the toolkit. 
The two morpheme-based decoders have been added into src/bin and src/bin/Makefile.
1. latgen-biglm-faster-mapped.cc
2. MLDG-Decoder.cc
  They will be built while the toolkit is built. 
  they are the same in contents, but the names are different.
  latgen-biglm-faster-mapped is the name used in THUYG-20's original recipes.
  MLDG-Decoder is the name used in our paper.

THUYG-20 Data:
--------------------------
It's free for download at: https://openslr.org/22/

THUYG-20 recipes:
------------------------------------
You can run the scripts in egs/thuyg20 to reproduce our experimental results.
