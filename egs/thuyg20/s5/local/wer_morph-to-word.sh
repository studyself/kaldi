#Copyright 2016  Tsinghua University (Author: Dong Wang, Xuewei Zhang).  Apache 2.0.

#compute word error rate.
dir=$1
werdir=$dir/scoring_kaldi
for x in penalty_0.0 penalty_0.5 penalty_1.0;do
  for ((i=4;i<16;i++));do
    #convert morpheme to word
    local/morph-to-word.pl $werdir/$x/$i.txt $werdir/$x/$i.txt.word
  
   #remove the first word with the symbol  "_" 
	cat $werdir/$x/$i.txt.word | awk '{print $1}' | awk -F "_" '{print $1}' > tmp
	cat $werdir/$x/$i.txt.word | awk -F "_" '{print $2}' | tr -d "[a-z][]" | tr -d "[A-Z][]" > tmp1
	cat $werdir/$x/$i.txt.word | awk '{for(i=2;i<=NF;++i) printf $i "\t";printf "\n"}' > tmp2
	paste -d_ tmp tmp1 | paste - tmp2 > $werdir/$x/$i.txt.new
	rm tmp*
   
    #compute word error rate
    compute-wer --text --mode=present \
     ark:$werdir/test_filt.txt  ark,p:$werdir/$x/$i.txt.new > $dir/wer_${i}_${x}
  done
done

