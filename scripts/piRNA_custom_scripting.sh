#!/bin/bash
set -e
dashr=/lustre/scratch119/casm/team294rr/sl31/piRNA_new/plos_one_paper_ideas/dashr.v2.sncRNA.annotation.hg38.bed # replace path/to with actual path to file (DASHR ncRNA database)
index=/lustre/scratch119/casm/team78pipelines/reference/human/GRCh38_full_analysis_set_plus_decoy_hla/star/     # replace path/to with actual path to folder
cpu=8                                                                                                           # number of cores

star=/nfs/users/nfs_r/rr11/Tools/STAR-2.5.2a/bin/Linux_x86_64_static/STAR

samtools=/software/CASM/modules/installs/samtools/samtools-1.9/bin/samtools
intersectBed=/software/CASM/modules/installs/bedtools/bedtools-2.29.0/bin/intersectBed

PATH=$PATH:/nfs/users/nfs_s/sl31/sean-lustre117-team294/pirna-analysis/subread-2.0.1-Linux-x86_64/bin/ #featurecounts
#PATH=$PATH:/software/CASM/modules/installs/samtools/samtools-1.9/bin/
PATH=$PATH:/nfs/users/nfs_s/sl31/.homebrew_lstr/bin # bioawk

############################################
#Generate ncRNA file for filtering

if [ ! -f 'ncRNAs.bed' ]; then
  grep -v "piRNA" "$dashr" > ncRNAs.bed
fi

# replace path/to with actual path to file
bed_ncRNA=$(realpath ncRNAs.bed)

############################################

i="$1"

if [ ! -f "$i" ]; then
  echo "File does not exist: $i"
  exit 1
else
  # get realpath for input file as we change folders a lot here
  i="$(realpath "$i")"
fi

base=$(basename "$i" .fastq)

mkdir "$base"
cd "$base"

bioawk -cfastx 'length($seq) > 1 {print "@"$name"\n"$seq"\n+\n"$qual}' "$i" > "$base.emptyless.fq"

echo "-->>>---Initiating STAR for $base---<<<---"
echo ""

$star --genomeDir $index \
  --genomeLoad NoSharedMemory \
  --runThreadN $cpu \
  --readFilesIn "$base.emptyless.fq" \
  --outSAMstrandField intronMotif \
  --outFileNamePrefix $base.unfilt

$samtools sort $base.unfilt*.sam > $base.unfilt.bam

############################################################################

echo "filtering by size (24-34) $base"

$samtools view -h $base.unfilt.bam | awk 'length($10) > 23 || $1 ~ /^@/' | awk 'length($10) < 35 || $1 ~ /^@/' | $samtools view -bS - > $base.lenFilt.bam

$samtools view -h $base.lenFilt.bam > $base.lenFilt.sam

##############################################################################

echo "filtering ncRNAs $base"

$intersectBed -s -v -f 0.2 -abam $base.lenFilt.bam -b "$bed_ncRNA" > $base.lenFilt.ncFilt.bam

$samtools view -h $base.lenFilt.ncFilt.bam > $base.lenFilt.ncFilt.sam

#### counting reads in piRNAs ############

#htseq-count $base.lenFilt.sam $gtf_piR > $base.counts_pir.lenFilt.txt

#htseq-count $base.lenFilt.ncFilt.sam $gtf_piR > $base.counts_pir.lenFilt.ncFilt.txt

echo ""
echo "---->>>----Finish $base----<<<-----"
echo ""
cd ..

#done
