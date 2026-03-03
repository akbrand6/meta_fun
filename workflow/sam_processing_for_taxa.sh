#!/bin/bash

# This is the only line that should need to be updated in this code, just the input fasta
input_fasta=$1

index="/zfs/omics/projects/metatools/DB/eukdetect_database_v2/ncbi_eukprot_met_arch_markers.fna"

PREFIX=$( basename $input_fasta )
bowtie2 --local -x $index -f $input_fasta -S $PREFIX.sam

# 1. Keep only mapped reads
samtools view -F 4 $PREFIX.sam > ${PREFIX}.mapped.sam

# 2. Count hits per marker
cut -f3 ${PREFIX}.mapped.sam | sort | uniq -c | sort -nr > ${PREFIX}_marker_counts.txt

# 3. Reformat (marker first, count second) for parsing
awk '{print $2 "\t" $1}' ${PREFIX}_marker_counts.txt > ${PREFIX}_marker_counts_reformatted.txt

# 4. Summarize at "species/strain" level directly from marker IDs
awk '{split($1,a,"-"); species=a[2]"_"a[3]; count=$2; sum[species]+=count} \
     END {for (s in sum) print s"\t"sum[s]}' ${PREFIX}_marker_counts_reformatted.txt \
     | sort -k2,2nr > ${PREFIX}_species_summary.txt

# 5. Collapse to species level (drop strain / taxid suffixes)
awk '{split($1,a,"_"); species=a[1]"_"a[2]; count=$2; sum[species]+=count} \
     END {for (s in sum) print s"\t"sum[s]}' ${PREFIX}_species_summary.txt \
     | sort -k2,2nr > ${PREFIX}_species_summary_collapsed.txt

echo "Done! Files generated:"
echo "  ${PREFIX}.mapped.sam"
echo "  ${PREFIX}_marker_counts.txt"
rm ${PREFIX}_marker_counts_reformatted.txt
rm ${PREFIX}_species_summary.txt
echo "  ${PREFIX}_species_summary_collapsed.txt"
