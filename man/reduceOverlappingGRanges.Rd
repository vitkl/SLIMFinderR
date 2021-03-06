% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/benchmarkMotifs.R
\name{reduceOverlappingGRanges}
\alias{reduceOverlappingGRanges}
\title{Reduce Overlapping GRanges keeping metadata (collapsing withing each column separated by pipes)}
\usage{
reduceOverlappingGRanges(GRanges, minoverlap = 5,
  merge_motif_variants = F, ...)
}
\arguments{
\item{GRanges}{any Genomic Ranges object with metadata (mcols())}

\item{minoverlap}{min overlap between Genomic Ranges to continue with reduce}
}
\value{
reduced Genomic Ranges object
}
\description{
Reduce Overlapping GRanges keeping metadata (collapsing withing each column separated by pipes)
}
\author{
Vitalii Kleshchevnikov
}
