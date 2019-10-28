backend=tfidf

for split in $(seq 0 9); do
   for level in $(seq 1 5); do
       echo [${backend}_split${split}_level${level}] >> projects.cfg;
	echo name=${backend} split ${split} level ${level} >> projects.cfg;
	echo language=nl >> projects.cfg;
	echo backend=tfidf >> projects.cfg;
	echo 'analyzer=snowball(dutch)' >> projects.cfg;
	echo limit=$(( $level > 1 ? 5 : 1 )) >> projects.cfg;
	echo vocab=MPIER >> projects.cfg;
	echo  >> projects.cfg;
   done; 
done;
