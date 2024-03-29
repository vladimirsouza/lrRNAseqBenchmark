% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{add_variant_density_of_a_method}
\alias{add_variant_density_of_a_method}
\title{Add column of density of variants around each variant called by a method}
\usage{
add_variant_density_of_a_method(input_table, window_size, used_methods)
}
\arguments{
\item{input_table}{A data.frame. The input master table.}

\item{window_size}{A 1-length integer. The size of the window where variants
are used to calculate the density of variants around a each variant called
by the specified method.}

\item{used_methods}{A vector of strings. The names of the methods to be used.}
}
\value{
A data.frame.
}
\description{
Add column of density of variants around each variant called by a method
}
