% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/create_master_table.R
\name{add_read_coverage_from_bam_to_master_table}
\alias{add_read_coverage_from_bam_to_master_table}
\title{Add read coverage (taken from BAM file) of each dataset to a master table}
\usage{
add_read_coverage_from_bam_to_master_table(..., input_table, dataset_names)
}
\arguments{
\item{...}{Objects generated by \code{IRanges::coverage} function.}

\item{input_table}{A master table to add read-coverage columns.}

\item{dataset_names}{Vector of strings in which each element is the identification
(name) of each input object in '...'. The order of these elements must be in
accordance with the order of the input objects in '...', and its length must be
the same as the number of input VCF objects in '...'.}
}
\value{
A data frame.
}
\description{
Add read coverage (taken from BAM file) of each dataset to a master table
}