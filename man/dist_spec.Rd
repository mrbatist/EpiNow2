% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dist.R
\name{dist_spec}
\alias{dist_spec}
\title{Specify a distribution.}
\usage{
dist_spec(
  mean,
  sd = 0,
  mean_sd = 0,
  sd_sd = 0,
  dist = c("lognormal", "gamma"),
  max = NULL,
  fixed = FALSE
)
}
\arguments{
\item{mean}{Numeric. If the only non-zero summary parameter
then this is the fixed interval of the distribution. If the \code{sd} is
non-zero then this is the mean of the distribution given by \code{dist}.
If this is not given a vector of empty vectors is returned.}

\item{sd}{Numeric, defaults to 0. Sets the standard deviation of the
distribution.}

\item{mean_sd}{Numeric, defaults to 0. Sets the standard deviation of the
uncertainty around the mean of the  distribution assuming a normal
prior.}

\item{sd_sd}{Numeric, defaults to 0. Sets the standard deviation of the
uncertainty around the sd of the  distribution assuming a normal prior.}

\item{dist}{Character, defaults to "lognormal". The (discretised
distribution to be used. If sd == 0 then the distribution  is fixed and a
delta function is used. If sd > 0 then the distribution is discretised and
truncated.

The following distributions are currently supported:
\itemize{
\item "lognormal" - a lognormal distribution. For this distribution \code{mean}
is the mean of the natural logarithm of the delay (on the log scale) and
\code{sd} is the standard deviation of the natural logarithm of the delay.
\item "gamma" - a gamma distribution. For this distribution \code{mean} is the
mean of the delay and \code{sd} is the standard deviation of the delay. During
model fitting these are then transformed to the shape and scale of the gamma
distribution.
}

When \code{dist} is the default lognormal distribution the other function
arguments have the following definition:
\itemize{
\item \code{mean} is the mean of the natural logarithm of the delay (on the
log scale).
\item \code{sd} is the standard deviation of the natural logarithm of the delay.
}}

\item{max}{Numeric, maximum value of the distribution. The distribution will
be truncated at this value.}

\item{fixed}{Logical, defaults to \code{FALSE}. Should delays be treated
as coming from fixed (vs uncertain) distributions. Making this simplification
reduces compute requirement but may produce spuriously precise estimates.}
}
\value{
A list of distribution options.
}
\description{
\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#stable}{\figure{lifecycle-stable.svg}{options: alt='[Stable]'}}}{\strong{[Stable]}}
Defines the parameters of a supported distribution for use in onward
modelling. Multiple distribution families are supported - see the
documentation for \code{family} for details. This function provides distribution
functionality in \code{\link[=delay_opts]{delay_opts()}}, \code{\link[=generation_time_opts]{generation_time_opts()}}, and
\code{\link[=trunc_opts]{trunc_opts()}}.
}
\author{
Sebastian Funk

Sam Abbott
}
