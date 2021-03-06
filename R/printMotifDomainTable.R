##' \code{printMotifDomainTable} combines Domain enrichment and Motif search results
##' @name printMotifDomainTable
##' @param input object of class XYZinteration_XZEmpiricalPval and should be the output of permutationPval()
##' @param doman_viral_pairs if TRUE - remove human proteins to have a row per viral protein - human domain pair, if FALSE a row is per viral protein - human domain - human protein.
##' @param motifs add motif search results?
##' @param destfile file where to save the resulting table
##' @param fdr_pval_thresh FDR threshold p-value for Domain enrichment analysis
##' @param only_with_motifs show enriched domains only if motif in viral proteins are also present (if FALSE - show all results)
##' @param fdr_motifs FDR threshold p-value for Motif search analysis
##' @param occurence_QSLIMFinder data.table containing the motif occurence output of the QSLIMFinder
##' @param comparimotif_wdb data.table containing the output of the comparimotif tool (comparing motifs from \code{occurence_QSLIMFinder} to ELM DB)
##' @param print_table if TRUE calls DT:datatable to print the interactive results table
##' @param one_from_cloud pick only one motif per motif cloud by the lowest p-value (before multiple hypothesis testing correction)
##' @author Vitalii Kleshchevnikov
##' @import data.table
##' @importFrom DT datatable
##' @export printMotifDomainTable
printMotifDomainTable = function(input, doman_viral_pairs = F, motifs = F, destfile, fdr_pval_thresh = 0.05, only_with_motifs = F, fdr_motifs = 1, occurence_QSLIMFinder = NA, comparimotif_wdb = NA, patterns_QSLIMFinder = NA, print_table = T, one_from_cloud = T, entry.list = NULL){
  res = copy(input)

  res = XYZ.p.adjust(res, method = "fdr")
  res$data_with_pval = res$data_with_pval[fdr_pval < fdr_pval_thresh]

  res$data_with_pval[, human_domain_url := paste0("<a href='https://www.ebi.ac.uk/interpro/entry/",IDs_domain_human,"'>",IDs_domain_human,"</a>")]
  res$data_with_pval[, human_interactor_url := paste0("<a href='http://www.uniprot.org/uniprot/",IDs_interactor_human,"'>",IDs_interactor_human,"</a>")]
  res$data_with_pval[, viral_interactor_url := paste0("<a href='http://www.uniprot.org/uniprot/",IDs_interactor_viral,"'>",IDs_interactor_viral,"</a>")]

  if(is.null(entry.list)) entry.list = getInterProEntryTypes("./entry.list")
  entry.list = unique(entry.list[,.(IDs_domain_human = ENTRY_AC, domain_name = ENTRY_NAME)])
  res$data_with_pval = entry.list[res$data_with_pval, on = "IDs_domain_human", allow.cartesian=TRUE]

  if(motifs){
    occurence_QSLIMFinder[, IDs_interactor_viral := gsub("_UNK__.+$","",Seq)]
    occurence_QSLIMFinder = unique(occurence_QSLIMFinder[,.(IDs_interactor_viral,
                                                            Motif_Pattern = Pattern,
                                                            Motif_pval = Sig,
                                                            Motif_Match = Match)])

    patterns_QSLIMFinder[, IDs_interactor_viral := gsub("^interactors_of\\.([[:alnum:]]{6,10}|[[:alnum:]]{6,10}-[[:digit:]]{1,3})\\.","",Dataset)]
    patterns_QSLIMFinder = unique(patterns_QSLIMFinder[,.(IDs_interactor_viral, Motif_Pattern = Pattern, Motif_IC = IC, Motif_SeqNum = SeqNum, Motif_OccNum = Occ, Motif_UPNum = UPNum, Motif_UPoccNum = UP, Cloud, Motif_Dataset = Dataset, Motif_pval = Sig)])

    if(one_from_cloud){
      patterns_QSLIMFinder[, order_in_cloud := order(Motif_pval), by = .(Motif_Dataset, Cloud)]
      patterns_QSLIMFinder = patterns_QSLIMFinder[order_in_cloud == 1][, c("order_in_cloud", "Cloud") := NULL]
    }
    patterns_QSLIMFinder = patterns_QSLIMFinder[p.adjust(Motif_pval, "fdr") < fdr_motifs]

    occurence_QSLIMFinder = patterns_QSLIMFinder[occurence_QSLIMFinder, on = c("IDs_interactor_viral", "Motif_Pattern", "Motif_pval")]

    comparimotif_wdb = unique(comparimotif_wdb[,.(Motif1, Motif2, Name2, NormIC)])
    comparimotif_wdb = comparimotif_wdb[!grepl("CLV",Name2) & !grepl("TRG",Name2)]
    comparimotif_wdb[, Name2 := gsub("_[[:alpha:]]{1}$","",Name2)]
    comparimotif_wdb[, Motif2 := paste0(Motif2[1], collapse = "|"), by = .(Motif1, Name2)]
    comparimotif_wdb[, NormIC := mean(NormIC), by = .(Motif1, Name2)]
    comparimotif_wdb = unique(comparimotif_wdb)
    comparimotif_wdb[, motif_mapping := paste0(Name2,"(normIC:",NormIC,")", collapse = "; "), by = Motif1]
    comparimotif_wdb[, motif..............................................pattern_mapping := paste0(Name2,":",Motif2,"", collapse = "; "), by = Motif1]
    comparimotif_wdb = unique(comparimotif_wdb[,.(Motif_Pattern = Motif1, motif_mapping, motif..............................................pattern_mapping)])

    occurence_QSLIMFinder = comparimotif_wdb[occurence_QSLIMFinder, on = "Motif_Pattern"]

    res$data_with_pval = occurence_QSLIMFinder[res$data_with_pval, on = "IDs_interactor_viral", allow.cartesian=TRUE]
    res$data_with_pval = res$data_with_pval[, .(human_domain = IDs_domain_human,
                                                domain_name = domain_name,
                                                viral_interactor = IDs_interactor_viral,
                                                human_interactor = IDs_interactor_human,
                                                p.value, fdr_pval, observed_statistic,
                                                human_domain_url, human_interactor_url, viral_interactor_url,
                                                domain_count_per_viral_interactor = domain_count_per_IDs_interactor_viral,
                                                viral_interactor_degree = IDs_interactor_viral_degree,
                                                total_domain_count = domain_count,
                                                human_interactor_degree = IDs_interactor_human_degree,
                                                total_background_proteins = N_prot_w_interactors,
                                                Motif_Pattern, Motif_pval, Motif_Match,
                                                Motif_IC,  Motif_SeqNum,  Motif_OccNum,  Motif_UPNum,  Motif_UPoccNum, Motif_Dataset,
                                                motif_mapping, motif..............................................pattern_mapping)]
    if(only_with_motifs) res$data_with_pval = res$data_with_pval[!is.na(Motif_Pattern)]
  } else {
    res$data_with_pval = res$data_with_pval[, .(human_domain = IDs_domain_human,
                                                domain_name = domain_name,
                                                viral_interactor = IDs_interactor_viral,
                                                human_interactor = IDs_interactor_human,
                                                p.value, fdr_pval, observed_statistic,
                                                human_domain_url, human_interactor_url, viral_interactor_url,
                                                domain_count_per_viral_interactor = domain_count_per_IDs_interactor_viral,
                                                viral_interactor_degree = IDs_interactor_viral_degree,
                                                total_domain_count = domain_count,
                                                human_interactor_degree = IDs_interactor_human_degree,
                                                total_background_proteins = N_prot_w_interactors)]
  }

  res$data_with_pval = unique(res$data_with_pval)

  if(doman_viral_pairs){
    res$data_with_pval[, c("human_interactor", "human_interactor_degree", "human_interactor_url") := NULL]
    res$data_with_pval = unique(res$data_with_pval)
  }

  fwrite(res$data_with_pval[order(p.value, decreasing = F)], destfile, sep = "\t")
  if(print_table) DT::datatable(res$data_with_pval[order(p.value, decreasing = F)], escape = FALSE)
  return(res$data_with_pval[order(p.value, decreasing = F)])
}
