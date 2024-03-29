% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{make_homopolymer_table_to_plot}
\alias{make_homopolymer_table_to_plot}
\title{Organize the data used to make plots about homopolymer analysis}
\usage{
make_homopolymer_table_to_plot(
  input_hom_table,
  variant_type,
  method_name,
  truth_name,
  hom_length_intervals,
  interval_names,
  to_calculate,
  output_method_name
)
}
\arguments{
\item{input_hom_table}{A data.frame generated by function `method_homopolymer_indels`.}

\item{variant_type}{A 1-length string. Possible values are "insertion" or "deletion".}

\item{method_name}{A 1-length string. The name of the method from which is desired
to extract information.}

\item{truth_name}{A 1-length string. The name of the ground-truth.}

\item{hom_length_intervals}{A vector of integers. The minimum for each interval of
homopolymer length. Each interval `i` ranges from `hom_length_intervals[i]` to
`hom_length_intervals[i+1]`, except the last interval which upper limit is `Inf`.}

\item{interval_names}{A vector of characters with the same length of
`hom_length_intervals`. The name for each interval of homopolymer length.}

\item{to_calculate}{A 1-length string. Possible values are "rates" or "pre_rec_f1".
If "rates", the functin calculates the rates of TPs, FNs and FPs. If "pre_rec_f1",
it calculates the precision, the recall and the F1-score.}

\item{output_method_name}{A 1-length string. The label of the method specified in
`method_name` to be output.}
}
\value{
A 2-length list (`class_counts` and `dat_text`).
}
\description{
The user may want to use this function several times to pull information about
  different combinations between `variant_type` and `method_name` from
  `input_hom_table`. In the future, the function should make the job automatically
  using loops.
}
