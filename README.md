MLDG-Decoder for THUYG-20

THUYG-20 Data:
https://openslr.org/22/

THUYG-20 recipes:
egs/thuyg20

We add 2 files:
1. latgen-biglm-faster-mapped.cc
2. MLDG-Decoder.cc

they are the same, but the names are different.

latgen-biglm-faster-mapped is the name used in THUYG-20's original recipes.

MLDG-Decoder is the name used in our paper.

To use the morpheme-based decoder, You have to:
1) build Kaldi with latgen-biglm-faster-mapped.cc in src/bin
2) run THUYG-20 recipes in egs/thuyg20 to test the decoder.
3) latgen-biglm-faster-mapped is used in decode_biglm.sh
