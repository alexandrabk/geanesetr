updateHGNCdict = function(){

  custom_url = "https://www.genenames.org/cgi-bin/download?col=gd_hgnc_id&col=gd_app_sym&col=gd_status&col=gd_locus_type&col=gd_prev_sym&col=gd_aliases&col=gd_pub_chrom_map&col=gd_pub_acc_ids&col=gd_enz_ids&col=gd_pub_eg_id&col=gd_pub_ensembl_id&col=gd_mgd_id&col=gd_other_ids_list&col=gd_pubmed_ids&col=gd_pub_refseq_ids&col=gd_ccds_ids&col=gd_vega_ids&col=md_eg_id&col=md_mim_id&col=md_refseq_id&col=md_prot_id&col=md_ensembl_id&col=md_vega_id&col=md_ucsc_id&col=md_mgd_id&col=md_rgd_id&col=md_rna_central_ids&col=md_lncipedia&status=Approved&status_opt=2&where=&order_by=gd_app_sym_sort&format=text&limit=&hgnc_dbtag=on&submit=submit"

  payload = httr::GET(custom_url)

  txt = httr::content(payload,"text")

  hugo_df = read.table(text = txt, stringsAsFactors=F, quote="", comment.char="", sep="\t",
    header = T)

  #uniprot data
  uniprot_url = "ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/idmapping/by_organism/HUMAN_9606_idmapping_selected.tab.gz"
  uniprot_temp_dir = "./uniprot_tempfile"
  dir.create(uniprot_temp_dir)
  download.file(uniprot_url,"./uniprot_tempfile/HUMAN_9606_idmapping_selected.tab.gz")
  uniprot = read.table("./uniprot_tempfile/HUMAN_9606_idmapping_selected.tab.gz", sep = "\t", quote = "", comment.char = "", stringsAsFactors = F)

  hugo_df$uniprot_symbol = gsub("_HUMAN","",uniprot[match(hugo_df$Ensembl.ID.supplied.by.Ensembl.,uniprot$V19),"V2"])

  #build named vector to act as hash object
  #Note: actual hash object of size required results in segfault

  syns = plyr::dlply(hugo_df,plyr::.(Approved.symbol),function(row){
    keys = c(unlist(strsplit(row$Synonyms,",")),
      unlist(strsplit(row$Previous.symbols,",")),
      unlist(strsplit(row$Accession.numbers,",")),
      unlist(strsplit(row$Ensembl.gene.ID,",")),
      unlist(strsplit(row$UniProt.ID.supplied.by.UniProt.,",")),
      unlist(strsplit(row$UCSC.ID.supplied.by.UCSC.,",")),
      unlist(strsplit(row$RefSeq.IDs,",")),
      unlist(strsplit(row$uniprot_symbol,",")))
    keys = gsub(" ","",keys)
    keys = unique(keys)
    return(keys)
  })

  hgnc_df = genesetr::dfcols.tochar(stack(syns))
  colnames(hgnc_df) = c('syns','approved')


  #ensure none of the keys (alternate symbols/synonyms) are
  #identical to the values (approved symbols)
  hgnc_df = hgnc_df[!hgnc_df$syns %in% hgnc_df$approved,]
  hgnc_df = hgnc_df[!duplicated(hgnc_df$syns),]

  hgnc_dict = c(hgnc_df$approved,unique(hgnc_df$approved))
  names(hgnc_dict) = c(hgnc_df$syns,unique(hgnc_df$approved))

  usethis::use_data(hugo_df, overwrite = T)
  usethis::use_data(hgnc_dict, overwrite = T)
  unlink("./uniprot_tempfile/")

}
