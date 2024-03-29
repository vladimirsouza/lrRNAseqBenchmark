% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/create_master_table.R
\name{add_qual_from_vcf}
\alias{add_qual_from_vcf}
\title{Add QUAL from a VCF into a master table}
\usage{
add_qual_from_vcf(input_table, method_name, vcf_file)
}
\arguments{
\item{input_table}{A data.frame. The master table to add the new column.}

\item{method_name}{A 1-lenght string. The name of the method from which is
desirable to get the QUAL values. The new column is named as 
"qual_<method_name>".}

\item{vcf_file}{A 1-lenght string. The path of the VCF file from which the
the QUAL values are extracted.}
}
\value{
A data.frame
}
\description{
Add QUAL to master table.
}
