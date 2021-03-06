% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/select_vpfiles.R
\name{match_filenames}
\alias{match_filenames}
\title{Match a set of regex expression to a list of files}
\usage{
match_filenames(filelist, regexlist)
}
\arguments{
\item{filelist}{Character list of filenames/filepaths.}

\item{regexlist}{Character list of regex expressions to which the file names
should comply.}
}
\value{
Character subset of filenames from the filelist that comply to any
of the provided regex expressions
}
\description{
Match a set of regex expression to a list of files and return those filenames
that comply to any of the provided regex expressions. This function basically
wraps a grep to make it working on vectors by combining the vector of
regex options as possible options
}
\keyword{internal}
