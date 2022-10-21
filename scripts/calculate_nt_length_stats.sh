#!/usr/bin/env bash
module load bedtools
module load samtools

if [ ! -d "sncRNA_stats" ]; then
  mkdir sncRNA_stats
fi

# get the unfiltered bams generated by the piRNA_custom_scripting.sh script
# ie. after alignment by STAR and before reads were removed from bams by nt size
# generate a list of the lengths of reads
find . -name "*.unfilt.bam" -print0 | while read -d $'\0' file; do
  basename_file="$(basename "$file" | sed 's/.unfilt.bam//g' | sed 's/Aligned.sortedByCoord.out//g' | sed 's/_S[0-9]*_merged_R1_001_trimmed.4.clean.fq//g')"
  job_name="$basename_file".read_lengths
  echo "$job_name"

  bsub -J "read_lengths" -e sncRNA_stats/$job_name.e -o sncRNA_stats/$job_name.o -R'select[mem>8000] rusage[mem=8000]' -M8000 -n 1 -R'span[hosts=1]' \
    "samtools view "$file" | awk '{print length(\$10)}' > sncRNA_stats/"$basename_file".read_lengths.txt"
done
bwait -w 'ended("read_lengths")'

# run a bedtools intersect between each of the unfiltered bams and the DASHR
# database and export as a bed file with all the annotations
find . -name "*.unfilt.bam" -print0 | while read -d $'\0' file; do
  basename_file="$(basename "$file" | sed 's/.unfilt.bam//g' | sed 's/Aligned.sortedByCoord.out//g' | sed 's/_S[0-9]*_merged_R1_001_trimmed.4.clean.fq//g')"
  job_name="$basename_file".sncRNA_stats

  bsub -J "dashrintersect" -e sncRNA_stats/$job_name.e -o sncRNA_stats/$job_name.o -R'select[mem>40000] rusage[mem=40000]' -M40000 -n 1 -R'span[hosts=1]' \
    "intersectBed -s -f 0.2 \
		-abam "$file" \
		-b /lustre/scratch119/casm/team294rr/sl31/piRNA_new/plos_one_paper_ideas/dashr.v2.sncRNA.annotation.hg38.bed \
		-bed -wa -wb | gzip > "sncRNA_stats/$basename_file".dashrintersect.bed.gz"
done
