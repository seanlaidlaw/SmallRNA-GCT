#!/usr/bin/env Rscript

library(data.table)

i = 0
for (file in list.files(path = "sncRNA_stats", pattern = "*.dashrintersect.bed.gz", full.names = T)) {

  print(paste0("processing file: ", file))

  z = fread(file, sep = "\t")
  z = as.data.frame(z)
  z = z[c("V17")]
  colnames(z) = c("sncRNA_family")
  suppressMessages(gc())

  cell_name = gsub(".dashrintersect.bed.gz","", file)
  cell_name = gsub(".*/","",cell_name)


  freq_category_z = as.data.frame(table(z$sncRNA_family))
  colnames(freq_category_z)[1] = "sncRNA_family"
  colnames(freq_category_z)[2] = cell_name

  if (i ==0) {
    freq_category = freq_category_z
  } else {
    freq_category = merge(freq_category, freq_category_z)
  }

  i = i + 1
}
write.table(freq_category, file = "sncRNA_stats/sncRNA_family_counts.tsv", sep = "\t")
