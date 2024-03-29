#' Initiate master table
#'
#' This function create the first columns of the master table. Those columns indicate
#' whether a method could call of not a variant. A master table is used to get
#' information form VCF files generated from different methods and compare to
#' ground-truth VCF files.
#'
#' @param ... VCF file addresses.
#' @param method_names Vector of strings in which each element is the identification
#'   (name) of each input VCF files. The order of these elements must be in accordance
#'   with the order of the input files, and its length must be the same as the number
#'   of input VCF files.
#'
#' @return A data.frame.
#'
#' @importFrom stats setNames
#' @importFrom rlang .data
#' @importFrom vcfR read.vcfR
#' @import dplyr
#'
#' @export
initiate_master_table <- function(..., method_names) {
  ### load PASS variants
  vcf_file_list <- list(...)
  
  if( length(vcf_file_list) != length(method_names) ) {
    stop("Length of method_names must be the same as the number of input VCF files.")
  }
  
  vcfs <- lapply(vcf_file_list, function(vcf_file) {
    vcf <- read.vcfR(vcf_file)
    vcf <- cbind(vcf@fix, vcf@gt)
    vcf <- as.data.frame(vcf)
    vcf$POS <- as.integer(vcf$POS)
    vcf$QUAL <- as.numeric(vcf$QUAL)
    vcf[ vcf$FILTER=="PASS", ]
  })
  
  ### split VCFs by chromosomes
  present_chromosomes <- bind_rows(vcfs) %>%
    pull(1) %>%
    unique
  vcfs <- sapply(vcfs, function(vcf) {
    lapply(present_chromosomes, function(pchrm) {
      vcf[ vcf[,1]==pchrm, ]
    })
  })
  
  ### which variants are contained in each vcf and what are ther DP tag (from VCF file)
  master_table <- apply(vcfs, 1, function(vcfs_chrmI) {
    all_positions <- bind_rows(vcfs_chrmI) %>%
      pull(2) %>%
      unique %>%
      sort
    in_chrmI_methodJ <- sapply(vcfs_chrmI, function(vcf_chrmI_methodJ) {
      1 * ( all_positions %in% vcf_chrmI_methodJ[[2]] )
    })
    
    dv_chrmI_methodJ <- sapply(vcfs_chrmI, function(vcf_chrmI_methodJ) {
      res <- strsplit(vcf_chrmI_methodJ[[10]], ":") %>%
        sapply("[", 3) %>%
        as.integer() %>%
        setNames(vcf_chrmI_methodJ[[2]])
      res <- unname( res[ as.character(all_positions) ] )
    })
    
    data.frame(pos=all_positions,
               in_chrmI_methodJ,
               dv_chrmI_methodJ)
  })
  master_table <- mapply(function(pc, mt){
    cbind(chrm=pc, mt)
  }, present_chromosomes, master_table, SIMPLIFY=FALSE)
  
  master_table <- bind_rows(master_table)
  
  method_names <- c( paste0("in_", method_names),
                     paste0("dp_", method_names) )
  names(master_table)[-(1:2)] <- method_names
  
  master_table
}






#' Get all splice sites positions of a BAM files
#'
#' Get the position of all splice sites in a BAM file and the number of reads that
#' support each one of them. Besides that, indicate whether the splice site is
#' acceptor or donor site.
#'
#' This function may take several hours to run.
#'
#' @param input_bam The input BAM file to extract splice site positions from.
#' @param threads Number of threads.
#'
#' @return A data.frame in which each row is a splice-site position.
#'
#' @importFrom GenomicAlignments extractAlignmentRangesOnReference cigar start
#'   end seqnames
#' @importFrom BiocParallel MulticoreParam bpmapply
#' @importFrom utils head
#' @importFrom rlang .data
#' @importFrom dplyr group_by
#' @importFrom dplyr tally
#'
#' @export
get_splice_sites_info <- function(input_bam, threads){
  ss <- extractAlignmentRangesOnReference( cigar(input_bam), start(input_bam) )

  # add chromossome name
  chrm_name <- as.vector( seqnames(input_bam) )

  multicoreParam <- MulticoreParam(workers = threads)
  ss <- bpmapply(function(ss_i, chrm_name_i){
    if(length(ss_i) > 1){
      ss_start <- start(ss_i)[-1]
      ss_end <- head( end(ss_i), -1 )
      is_acceptor_site <- rep( c(1L:0L), c( length(ss_start), length(ss_end) ) )
      data.frame(chrm= chrm_name_i, pos= c(ss_start, ss_end),
                 is_acceptor_site)
    }else{
      NULL
    }
  }, ss, chrm_name, BPPARAM=multicoreParam)

  ss <- do.call(rbind, ss)
  
  if( is.null(ss) )
    return(NULL)
  
  ss <- tally(
    group_by(ss, .data$chrm, .data$pos, .data$is_acceptor_site)
  )
  
  ss
}




#' Get all splice-sites and read-end positions of a BAM files
#'
#' Similar to \code{get_splice_sites_info}, but also count read ends.
#'
#' This function may take several hours to run.
#'
#' @param input_bam The input BAM file to extract splice site positions from.
#' @param threads Number of threads.
#'
#' @return A 2-element list (`splice_site`, and `transcript_end`). Element
#'   `splice_site` should contain the same returned by \code{get_splice_sites_info}.
#'   Element `transcript_end` counts of read ends (start or final/end site of the read).
#'
#' @importFrom GenomicAlignments extractAlignmentRangesOnReference cigar start
#'   end seqnames
#' @importFrom BiocParallel MulticoreParam bpmapply
#' @importFrom utils head
#' @importFrom rlang .data
#' @importFrom dplyr group_by tally
#'
#' @export
get_splice_sites_info2 <- function(input_bam, threads){

  ### find splice sites and read ends
  ss <- extractAlignmentRangesOnReference( cigar(input_bam), start(input_bam) )
  
  chrm_name <- as.vector( seqnames(input_bam) )
  multicoreParam <- MulticoreParam(workers = threads)
  ss <- bpmapply(function(ss_i, chrm_name_i){
    ss_start <- start(ss_i)
    ss_end <- end(ss_i)
    is_acceptor_site <- rep( c(1L:0L), c( length(ss_start), length(ss_end) ) )
    is_acceptor_site[ c(1, length(is_acceptor_site)) ] <- NA
    is_trans_left_end <- numeric( length(is_acceptor_site) )
    is_trans_left_end[1] <- 1
    data.frame(chrm= chrm_name_i, pos= c(ss_start, ss_end),
               is_acceptor_site, is_trans_left_end)
  }, ss, chrm_name, SIMPLIFY=FALSE, BPPARAM=multicoreParam)
  
  ss <- do.call(rbind, ss)
  if( is.null(ss) )
    return(NULL)
  
  ### separate splice sites and read ends
  k <- ifelse( is.na(ss$is_acceptor_site), "transcript_end", "splice_site")
  ss <- split(ss, k)
  
  ### count them per site
  ss$transcript_end <- group_by(ss$transcript_end,
                                .data$chrm, .data$pos, .data$is_trans_left_end)
  ss$transcript_end <- tally(ss$transcript_end)
  
  ss$splice_site <- group_by(ss$splice_site,
                             .data$chrm, .data$pos, .data$is_acceptor_site)
  ss$splice_site <- tally(ss$splice_site)
  
  ss
}





#' Add columns about spice sites to a master table
#'
#'
#'
#' @param input_table A data.frame generated by \code{initiate_master_table}.
#' @param splice_sites A data.frame generated by \code{get_splice_sites_info}.
#' @param max_dist_from_splice_site A 1-length integer (default is 20) that
#'   indicates the the maximum distance of a varaint from any splice site to
#'   consider it a variant near a splice site.
#' @param multiply_max_dist A 1-length integer (default is 100). To create the
#'   column `ss_shortest_dist` from column `ss_dist`, NA values (which means
#'   variables far from any splice site) are converted to integers. To make
#'   these integers be a high value, they are set to
#'   \code{max_dist_from_splice_site * multiply_max_dist}.
#'
#' @return A data.frame.
#'
#' @importFrom IRanges IRanges resize
#' @importFrom GenomicAlignments findOverlaps
#' @importFrom S4Vectors queryHits subjectHits
#' @importFrom rlang .data
#' @import dplyr
#'
#' @export
add_splice_site_info_to_master_table <- function(input_table,
                                                 splice_sites,
                                                 max_dist_from_splice_site=20,
                                                 multiply_max_dist=100) {
  if( !(names(input_table)[1] == "chrm") ){
    stop("First column of input_table is not 'chrm'.\nAre you sure input_table was created by initiate_master_table?")
  }
  if( !(names(input_table)[2] == "pos") ){
    stop("First column of input_table is not 'pos'.\nAre you sure input_table was created by initiate_master_table?")
  }

  splice_sites_split_by_chrm <- split(splice_sites, splice_sites$chrm)
  input_table_split_by_chrm <- names(splice_sites_split_by_chrm) %>%
    lapply(function(chrm_i) {
      table_chrmI <- input_table[ input_table$chrm==chrm_i, ]
      if( nrow(table_chrmI) > 0 ){
        table_chrmI
      }else{
        NULL
      }
    })

  table_ss <- mapply(function(table_i, ss_i){
    if( is.null(table_i) )
      return(NULL)
    ss_ir <- IRanges(ss_i$pos, width=1) %>%
      resize( width=2*max_dist_from_splice_site+1, fix="center" )
    re_ir <- IRanges(table_i$pos, width=1)
    ovl <- findOverlaps(re_ir, ss_ir)
    table_i$is_near_ss <- integer( nrow(table_i) )
    table_i$is_near_ss[ queryHits(ovl) ] <- 1L
    table_i$is_near_ss <- factor(table_i$is_near_ss, levels=0:1)

    ss_lines <- split( subjectHits(ovl), queryHits(ovl) )
    re_lines <- as.integer( names(ss_lines) )

    ss_num <- ss_dist <- is_acceptor_site <- as.list( rep(NA, nrow(table_i)) )

    k <- lapply(ss_lines, function(sl){
      ss_i$n[sl]
    })
    ss_num[ re_lines ] <- k

    k <- mapply(function(rl, sl){
      table_i[rl,"pos"] - ss_i[sl,"pos", drop=T]
    }, re_lines, ss_lines, SIMPLIFY=FALSE)
    ss_dist[ table_i$is_near_ss == 1] <- k

    k <- mapply(function(sl){
      ss_i[sl,"is_acceptor_site", drop=T]
    }, ss_lines, SIMPLIFY=FALSE, USE.NAMES=FALSE)
    is_acceptor_site[ table_i$is_near_ss == 1] <- k

    table_i$ss_dist <- ss_dist
    table_i$is_acceptor_site <- is_acceptor_site
    table_i$ss_num <- ss_num

    table_i$is_single_ss <- 1*( lengths(table_i$is_acceptor_site) == 1 )
    table_i$is_single_ss[ is.na(table_i$is_acceptor_site) ] <- -1
    table_i$is_single_ss <- factor( table_i$is_single_ss, levels=(-1):1 )

    table_i
  }, input_table_split_by_chrm, splice_sites_split_by_chrm, SIMPLIFY=FALSE)
  
  table_ss <- do.call(rbind, table_ss)
  rownames(table_ss) <- NULL


  #### motivaton for the next columns:
  #### use them with models like `randomForest::randomForest`
  table_ss$ss_shortest_dist <- sapply(
    table_ss$ss_dist, 
    function(u){
      # u mean the variant distances from all splice sites near it.
      # get the shortest distance.
      if( all(is.na(u)) ){
        max_dist_from_splice_site * multiply_max_dist
      }else{
        u[ which.min( abs(u) ) ]
      }
    }
  )
  table_ss$ss_highest_num <- sapply(
    table_ss$ss_num,
    function(u){
      # u mean the number of splice sites in the same position.
      # get the highest number of splice sites in the same position.
      if( all(is.na(u)) ){
        0
      }else{
        u[ which.max( abs(u) ) ]
      }
    }
  )
  table_ss$is_acceptor_site_mode <- sapply(table_ss$is_acceptor_site, function(x){
    # x indicates whether the splice sites near (for a same postion) a variant
    # are acceptor site (1) or not (0).
    # get the statistical mode of them.
    ux <- unique(x)
    k <- tabulate(match(x, ux))
    ux <- ux[ k==max(k) ]
    if(length(ux)>1){
      return(-1)
    }else{
      return(ux)
    }
  })
  table_ss$is_acceptor_site_mode <- factor(table_ss$is_acceptor_site_mode,
                                           levels=(-1):1)
  
  table_ss
}









#' Add read coverage (taken from BAM file) of each dataset to a master table
#'
#' @param input_table A master table to add read-coverage columns.
#' @param dataset_coverage Object generated by \code{IRanges::coverage} function.
#' @param dataset_name A 1-length string. Name of the dataset used to genere 
#'   `dataset_coverage`.
#'
#' @return A data frame.
#'
#' @importFrom rlang .data
#' @import dplyr
#'
#' @export
add_read_coverage_from_bam_to_master_table <- function(input_table, dataset_coverage, dataset_name) {
  table_dataset_coverage <- seq_along(dataset_coverage) %>%
    lapply(function(i) {
      chrm_i <- names(dataset_coverage)[i]
      input_table_i <- filter(input_table, .data$chrm==chrm_i)
      if( nrow(input_table_i)==0 )
        return(NULL)
      coverage_per_site <- as.vector( dataset_coverage[[i]] ) [input_table_i$pos]
      cbind(input_table_i, coverage_per_site)
    })
  table_dataset_coverage <- bind_rows(table_dataset_coverage)
  
  k <- names(table_dataset_coverage) == "coverage_per_site"
  names(table_dataset_coverage) [k] <- paste0(dataset_name, "_coverage")
  
  # rows of the ouput in the same order of input_table
  k <- paste(table_dataset_coverage$chrm, table_dataset_coverage$pos, sep="-")
  k1 <- paste(input_table$chrm, input_table$pos, sep="-")
  stopifnot( length(k)==length(k1) )
  stopifnot( anyDuplicated(k)==0 )
  stopifnot( anyDuplicated(k1)==0 )
  stopifnot( setequal(k,k1) )
  k <- order( factor(k, levels=k1, ordered=TRUE) )
  table_dataset_coverage[k,]
}








#' Add the count of N-cigar reads to the master table
#'
#' This function adds a new column to a master table with the counts of
#' N-cigar reads that overlap each site.
#'
#' @param input_table A data.frame. The master table to add the new column.
#' @param input_bam A `GenomicAlignments` object from which N-cigar-read counts
#'   are got.
#' @param dataset_name A 1-length string used to set the name of the new column.
#'
#' @return A data.frame.
#'
#' @importFrom GenomicAlignments cigarRangesAlongReferenceSpace cigar findOverlaps
#' @importFrom IRanges IRanges
#' @importFrom S4Vectors queryHits
#' @importFrom rlang .data
#' @import dplyr
#'
#' @export
add_number_of_n_cigar_reads_to_master_table <- function(input_table, input_bam, dataset_name=NULL) {
  bam_split_by_chrm <- split( input_bam, seqnames(input_bam) )

  table_NCigarReadCount <- seq_along(bam_split_by_chrm) %>%
    lapply(function(i) {
      chrm_i <- names(bam_split_by_chrm)[i]
      input_table_i <- filter(input_table, .data$chrm==chrm_i)
      if( nrow(input_table_i)==0 )
        return(NULL)

      Ns <- cigarRangesAlongReferenceSpace( cigar(bam_split_by_chrm[[i]]),
                                            ops="N",
                                            pos=start(bam_split_by_chrm[[i]]) )

      Ns <- unlist(Ns)
      variant_positions_ir <- IRanges(input_table_i$pos, width=1)
      ovl <- findOverlaps(variant_positions_ir, Ns)
      ovl <- table( queryHits(ovl) )
      n_cigar_read_count <- integer( nrow(input_table_i) )
      n_cigar_read_count [ as.integer(names(ovl)) ] <- as.vector(ovl)
      cbind(input_table_i, n_cigar_read_count)
    })
  table_NCigarReadCount <- bind_rows(table_NCigarReadCount) %>%
    right_join(input_table)
  column_name <- paste0(dataset_name, "_ncr_num")
  names(table_NCigarReadCount) [ncol(table_NCigarReadCount)] <- paste0(dataset_name, "_ncr_num")

  table_NCigarReadCount
}



#' Add column to compare two methods in a master table
#'
#' This function adds a column in a master table that compares two given methods.
#' The new column informs whether the variant was called only by the first method
#'   (`method1_name`), only by the second method (`method2_name`), by both
#'   methods (`"both"`), or neither of them (`"neither"`).
#'
#' @param input_table A data.frame. The master table to add the new column.
#' @param method1_name A 1-length string. The name of the first method.
#' @param method2_name A 1-length string. The name of the second method.
#'
#' @return A data.frame.
#'
#' @importFrom snakecase to_lower_camel_case
#' @importFrom rlang .data
#' @import dplyr
#'
#' @export
add_two_method_comparison_to_master_table <- function(input_table, method1_name, method2_name) {
  variant_called_only_by <- data.frame(
    in_metho1=c(1,1,0,0),
    in_metho2=c(1,0,1,0),
    compare_methods=factor(c("both", method1_name, method2_name, "neither"))
  )
  compare_methods <- paste(
    "compare",
    snakecase::to_lower_camel_case(method1_name),
    snakecase::to_lower_camel_case(method2_name),
    sep="_"
  )
  method1_name_in <- paste0("in_", method1_name)
  method2_name_in <- paste0("in_", method2_name)
  names(variant_called_only_by) <- c(method1_name_in, method2_name_in, compare_methods)

  left_join(input_table, variant_called_only_by)
}




#' Add classiffication of variants calls by comparing to the ground-truth to a
#'   master table
#'
#' Compare variants calls of a method to the ground-truth and classify each one
#'   as true-positiove (TP), false-negative (FN), false-positive (FP), or
#'   true-negative (TN).
#'
#' @param input_table A data.frame. The master table to add the new column.
#' @param method_name A 1-length string. The name of the method to compare to the
#'   ground-truth.
#' @param truth_name A 1-length string. The name of the ground-truth.
#' @param replace_column 1-length boolean (default is FALSE). If the classification
#'   column already exists and it is desired to replace it.
#'
#' @return A data.frame.
#'
#' @importFrom rlang .data
#' @import dplyr
#'
#' @export
add_method_vs_truth_comparison_to_master_table <- function(input_table,
                                                           method_name,
                                                           truth_name,
                                                           replace_column=FALSE){
  method_classification <- data.frame(
    in_method=c(1,1,0,0),
    in_truth=c(1,0,1,0),
    classification=factor(c("TP", "FP", "FN", "TN"))
  )
  classify_method_name <- paste(
    method_name,
    "classification",
    sep="_"
  )
  method_name_in <- paste0("in_", method_name)
  truth_name_in <- paste0("in_", truth_name)
  names(method_classification) <- c(method_name_in, truth_name_in, classify_method_name)
  
  if( !all( c(method_name_in, truth_name_in) %in% names(input_table) ) ){
    stop( gettextf("The input master table doesn't contain all columns: '%s' and '%s'.",
                   method_name_in, truth_name_in) )
  }
  
  if(replace_column){
    if( !any(names(input_table) == classify_method_name) ){
      stop( gettextf("Column '%s' doesn't exist.", classify_method_name) )
    }
    
    classify_method_name_original <- paste0(classify_method_name, "_original")
    k <- names(input_table) == classify_method_name
    names(input_table) [k] <- classify_method_name_original
    input_table <- left_join(input_table, method_classification)
    input_table[,classify_method_name_original] <- input_table[,classify_method_name]
    input_table <- input_table[,-ncol(input_table)]
    names(input_table) [names(input_table) == classify_method_name_original] <- classify_method_name
    input_table
  }else{
    if( any(names(input_table) == classify_method_name) ){
      stop( gettextf("Column '%s' already exists.", classify_method_name) )
    }
    
    left_join(input_table, method_classification)
  }
}






#' Add a column that states the variant type according a method or the ground truth
#' 
#' The new column stores the values "snp", "insertion", or "deletion",
#'   respectively to the variant type. If the variant type can not be defined --
#'   because the variant is heterozygous alternative and the alleles are a mix
#'   between SNP, insertion, or deletion -- the value returned is "mix".
#' 
#' @param input_table A data.frame. The master table to add the new column.
#' @param vcf_file 1-length string. The address of the VCF file.
#' @param method_name 1-length string. The name of the ground-truth or method.
#' 
#' @return A data.frame
#' 
#' @importFrom vcfR read.vcfR
#' 
#' @export
add_variant_type_to_master_table <- function(input_table, vcf_file, method_name) {
  
  vcf <- read.vcfR(vcf_file)
  
  k_gt <- sub(":.+", "", vcf@gt[,2])
  k_gt_sd <- standardize_genotype(k_gt)
  k_gt <- strsplit(k_gt, "/|\\|")
  k_gt_sd <- strsplit(k_gt_sd, "/")
  
  k_alt <- strsplit(vcf@fix[,5], ",")
  
  alt_len <- mapply(function(g, a){
    g <- as.integer(g[g!="0"])
    nchar(a[g])
  }, k_gt, k_alt, SIMPLIFY=FALSE)
  ref_len <- nchar(vcf@fix[,4])
  
  variant_type <- mapply(function(g, g_sd, a, r){
    ### there are situations in which a heterozygous alternative could 
    ### show alleles that are different types of variants, but i haven't
    ### addressed all of them here. examples of these situations are:
    ### * snps and insertions: ref=A ; alt=T,AT
    ### * snps and deletions: ref=AT ; alt=A,TT
    ### * insertions and deletions: ref=AT ; alt=A,ATT (need to confirm this)
    if( all(g_sd=="0") ){
      "homRef"
    }else{
      if( any(g_sd=="2") ){
        ### need to write this part of the code to find variant type "mix".
        "hetAlt"
      }else{
        if( r==unique(a) ){
          "snp"
        }else{
          ifelse(r>unique(a), "deletion", "insertion")
        }
      }
    }
  }, k_gt, k_gt_sd, alt_len, ref_len)
  
  k <- paste(vcf@fix[,1], vcf@fix[,2])
  variant_type <- setNames(variant_type, k)
  
  k <- paste0("in_", method_name)
  in_vcf <- input_table[,k] == 1
  k <- paste(input_table$chrm[in_vcf], input_table$pos[in_vcf])
  
  stopifnot( length(variant_type) == length(k) & 
               setequal(names(variant_type), k) )
  variant_type <- variant_type[k]
  
  k <- paste0("variantType_", method_name)
  input_table[,k] <- NA
  input_table[,k] [in_vcf] <- unname(variant_type)
  
  input_table
}










#' Add column that states whether the variant in the ground-truth is an indel or not
#' 
#' @param input_table A data.frame. The master table to add the new column.
#' @param vcf_file 1-length string. The address of the ground-truth VCF file.
#' @param truth_name 1-length string. The name of the ground-truth.
#'
#' @return A data.frame
#' 
#' @importFrom vcfR read.vcfR
#' 
#' @export
add_the_ground_truth_indel_information_to_master_table <- function(input_table, vcf_file, truth_name) {
  
  warning("This function is obsolete. It was replaced by 'is_indel_method'")
  
  vcf <- read.vcfR(vcf_file)
  k <- sub(":.+", "", vcf@gt[,2])
  k_gt <- strsplit(k, "/|\\|")
  
  k_alt <- strsplit(vcf@fix[,5], ",")
  
  alt_len <- mapply(function(g, a){
    g <- as.integer(g[g!="0"])
    nchar(a[g])
  }, k_gt, k_alt, SIMPLIFY=FALSE)
  ref_len <- nchar(vcf@fix[,4])
  
  is_any_indel <- mapply(function(a, r){
    any( c(a,r) != 1 )
  }, alt_len, ref_len)
  k <- paste(vcf@fix[,1], vcf@fix[,2])
  is_any_indel <- setNames(is_any_indel, k)
  
  k <- paste0("in_", truth_name)
  in_vcf <- input_table[,k] == 1
  k <- paste(input_table$chrm[in_vcf], input_table$pos[in_vcf])
  is_any_indel <- is_any_indel[k]
  
  k <- paste0("is_indel_", truth_name)
  input_table[,k] <- NA
  input_table[,k] [in_vcf] <- 1*unname(is_any_indel)
  
  input_table
}






#' Add column that states whether the variant called by a method is an indel or not
#'
#' @param input_table A data.frame. The master table to add the new column.
#' @param vcf_file 1-length string. The address of the method VCF file.
#' @param method_name 1-length string. The name of the method.
#' @param truth_name 1-length string. The name of the ground-truth.
#'
#' @return A data.frame
#' 
#' @export
add_a_method_indel_information_to_master_table <- function(input_table, vcf_file, method_name, truth_name) {
  
  warning("This function is obsolete. It was replaced by 'is_indel_method'")
  
  k <- paste0("is_indel_", truth_name)
  if( is.null(input_table[,k]) ) {
    stop_message <- gettextf("The column %s must exist in input_table.\nHave you forgotten to run add_the_ground_truth_indel_information_to_master_table?",
                             k)
    stop(stop_message)
  }
  
  add_method_indel_info <- add_the_ground_truth_indel_information_to_master_table
  input_table <- add_method_indel_info(input_table, vcf_file, method_name)
  
  is_indel_method_name <- paste0("is_indel_", method_name)
  is_indel_truth_name <- paste0("is_indel_", truth_name)
  k <- !is.na(input_table[,is_indel_truth_name])
  input_table[k, is_indel_method_name] <- input_table[k, is_indel_truth_name]
  
  input_table
}







#' Add a column to state whether the variant is an indel or not
#' 
#' To classify the variant as an indel, first the function looks at the VCF file
#' of the `first_method`. If the variant is not there, if looks at the VCF file
#' of the `second_method`.
#' 
#' Output meaning:
#'   * `-1` means that the variant type couldn't be defined, because it is 
#'     heterozygous alternative;
#'   * `0` means it is not an indel;
#'   * `1` means it is an indles;
#'   * `NA` means the `first_method` (and the `second_method`) didn't call the
#'     variant.
#' 
#' @param input_table A data.frame. The master table to add the new column.
#' @param first_method A 1-length string. The name of the first method.
#' @param second_method A 1-length string. The name of the second method
#'
#' @return A data.frame.
#' 
#' @export
is_indel_method <- function(input_table, first_method, second_method=NULL){
  vt_1st <- paste0("variantType_", first_method)
  vt_2nd <- paste0("variantType_", second_method)
  vt <- input_table[,vt_1st]
  k <- is.na(vt)
  if( !is.null(second_method) ){
    vt[k] <- input_table[k, vt_2nd]
  }else{
    second_method <- first_method
  }
  
  is_indel <- rep(-1, length(vt))
  is_indel [ vt=="snp" ] <- 0
  is_indel [ vt %in% c("deletion", "insertion") ] <- 1
  is_indel [ is.na(vt) ] <- NA
  
  input_table <- cbind(input_table, is_indel)
  names(input_table) [ncol(input_table)] <- paste0("is_indel_", second_method)
  
  input_table
}







#' Add homopolymer lengths to a master table
#' 
#' This function adds to the master table a column with the lengths of
#'   homopolymers, from the reference fasta, that overlaps positions POS + 1,
#'   where POS is the position of a variant. POS + 1 makes sence because
#'   minimp2 places homopolymer indels to the left of homopolymers, and , in
#'   case of indels, the column POS of VCF files means the position immediately
#'   to the left of the indel. In this way, homopolymer lengths of SNPs are
#'   meaningless. Moreover, homopolymer lengths of variants that are
#'   heterozygous alternatives should be meaningless as well. That is because
#'   they could contain alleles that are SNPs.
#'
#' @param input_table A data.frame. The master table to add the new column.
#' @param homopolymers A CompressedIRangesList object. It should store all 
#'   homopolymers, it's nucleotive types and lengths, of the genome used as
#'   the reference to call the variants. It is gerated by the function
#'   `sarlacc::homopolymers`.
#' @param ouput_what A string equal to "length" (default) or "nts". If
#'   "length", the lengths of homopolymers are ouput (1 for non-homopolymers).
#'   If "nts", the nucleotide type is output (NA for non-homopolymers).
#' 
#' @return A data.frame
#' 
#' @import IRanges
#' 
#' @export
add_homopolymer_length_when_indels <- function(input_table, homopolymers, ouput_what="length"){
  
  k <- ouput_what %in% c("length", "nts")
  if(!k){
    stop("Argument 'ouput_what' must be either 'length' or 'nts'.")
  }
  
  ### add homopolymer length into master table
  input_table_split <- split(input_table, input_table$chrm)
  homopolymers <- homopolymers[ names(input_table_split) ]
  input_table_hom <- mapply(function(d, h){
    d_pos <- IRanges( d$pos+1, width=1 )
    ovl <- findOverlaps(d_pos, h)
    homopolymer_length_indel <- rep(1L, nrow(d))
    if(ouput_what=="length"){
      homopolymer_length_indel[ queryHits(ovl) ] <- width(h) [ subjectHits(ovl) ]
    }else{
      homopolymer_length_indel[ queryHits(ovl) ] <- mcols(h)$base [ subjectHits(ovl) ]
    }
    cbind(d, homopolymer_length_indel)
  }, input_table_split, homopolymers, SIMPLIFY=FALSE)
  input_table_hom <- do.call(rbind, input_table_hom)
  if(ouput_what=="nts"){
    names(input_table_hom) [ncol(input_table_hom)] <- "homopolymer_nt_indel"
    k <- input_table_hom$homopolymer_nt_indel == "1"
    input_table_hom$homopolymer_nt_indel[k] <- NA
  }
  rownames(input_table_hom) <- NULL
  stopifnot( all(input_table[,1:2] == input_table_hom[,1:2]) )
  
  input_table_hom
}






#' Add QUAL from a VCF into a master table
#' 
#' Add QUAL to master table.
#'
#' @param input_table A data.frame. The master table to add the new column.
#' @param method_name A 1-lenght string. The name of the method from which is
#'   desirable to get the QUAL values. The new column is named as 
#'   "qual_<method_name>".
#' @param vcf_file A 1-lenght string. The path of the VCF file from which the
#'   the QUAL values are extracted.
#' 
#' @return A data.frame
#' 
#' @importFrom vcfR read.vcfR
#' @importFrom dplyr left_join
#' 
#' @export
add_qual_from_vcf <- function(input_table, method_name, vcf_file){
  vcf <- read.vcfR(vcf_file)
  qual <- vcf@fix[,colnames(vcf@fix) == "QUAL"]
  qual <- as.numeric(qual)
  qual <- data.frame(chrm=vcf@fix[,1],
                     pos=as.integer(vcf@fix[,2]),
                     qual)
  names(qual)[3] <- paste0("qual_", method_name)
  
  left_join(input_table, qual)
}


