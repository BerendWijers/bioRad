% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/download_vpfiles.R
\name{download_vpfiles}
\alias{download_vpfiles}
\title{Download vertical profile files (\code{vp}) from the ENRAM data repository}
\usage{
download_vpfiles(date_min, date_max, country, radar, directory = ".")
}
\arguments{
\item{date_min}{ISO fomat date indicating the first date to download
files from.}

\item{date_max}{ISO fomat date indicating the last date to download
files from}

\item{country}{Char vector with two letter country shortcuts.}

\item{radar}{Char vector with three letter radar sindicators. Make sure the
radars selected are in accordance to the country selection}

\item{directory}{Char defining the location to store the downloaded zip
folders and unzip into the default folder structure}
}
\description{
Download a set of vp bird profiles from the ENRAM repository. These are
stored within monthly available zip folders. This function downloads and
unzips them at a user defined location. Check
\href{http://enram.github.io/data-repository/}{http://enram.github.io/data-repository/}
for an overview of available data.
}
\examples{
my_path <- "~/my/directory/"
\dontrun{download_vpfiles("2016-10-01", "2016-11-30", c("be"),
c("jab", "wid"), directory = my_path)}
}
