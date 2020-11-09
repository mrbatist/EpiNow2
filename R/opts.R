#' Delay Distribution Options
#' 
#' @description Returns delay distributions formatted for usage by downstream 
#' functions.
#' @param ... Delay distributions as a list with the following parameters:
#' "mean", "mean_sd", "sd_mean", "sd_sd", and "max" defining a truncated log
#' normal (with all parameters except for max defined in logged form).
#' @seealso convert_to_logmean convert_to_logsd bootstrapped_dist_fit
#' @return A list summarising the input delay distributions.
#' @export
#' @examples
#' # no delays
#' delay_opts()
delay_opts <- function(...) {
  delays <- list(...)
  data <- list()
  data$delays <- length(delays)
  if (data$delays > 0) {
    delays <- purrr::transpose(delays)
  }
  
  # Estimate the mean delay -----------------------------------------------
  if (data$delays > 0) {
    data$seeding_time <- as.integer(sum(
      purrr::map2_dbl(delays$mean, delays$sd, ~ exp(.x + .y^2/2))
      ))
  }else{
    data$seeding_time <- 1
  } 
  data$delay_mean_mean <- allocate_delays(delays$mean, data$delays)
  data$delay_mean_sd <- allocate_delays(delays$mean_sd, data$delays)
  data$delay_sd_mean <- allocate_delays(delays$sd, data$delays)
  data$delay_sd_sd <- allocate_delays(delays$sd_sd, data$delays)
  data$max_delay <- allocate_delays(delays$max, data$delays)
  return(data)
}

#' Time-Varying Reproduction Number Options
#'
#' @description Defines a list specifying the optional arguments for the time-varying
#'  reproduction number. Custom settings can be supplied which override the defaults.
#'  
#' @param prior List containing named numeric elements "mean" and "sd". The mean and
#'  standard deviation of the log normal Rt prior. Defaults to mean of 1 and standard 
#'  deviation of 1.
#' @param use_rt Logical, defaults to `TRUE`. Should Rt be used to generate infections 
#'  and hence reported cases.
#' @param rw Numeric step size of the random walk, defaults to 0. To specify a weekly random 
#'   walk set `rw = 7`. For more custom break point settings consider passing in a `breakpoints`
#'   variable as outlined in the next section.
#' @param use_breakpoints Logical, defaults to `TRUE`. Should break points be used if present 
#'  as a `breakpoint` variable in the input data. Break points should be defined as 1 if present 
#'  and otherwise 0. By default breakpoints are fit jointly with a global non-parametric effect 
#'  and so represent a conservative estimate of break point changes (alter this by setting `gp = NULL`).
#' @return A list of settings defining the time-varying reproduction number
#' @inheritParams create_future_rt
#' @export
#' @examples
#' # default settings
#' rt_opts()
#' 
#' # add a custom length scale
#' rt_opts(prior = list(mean = 2, sd = 1))
#' 
#' # add a weekly random walk
#' rt_opts(rw = 7)
rt_opts <- function(prior = list(mean = 1, sd = 1),
                    use_rt = TRUE,
                    rw = 0,
                    use_breakpoints = TRUE,
                    future = "latest") {
  rt <- list(
    prior = prior,
    use_rt = use_rt,
    rw = rw,
    use_breakpoints = use_breakpoints,
    future = future
  )
  
  # replace default settings with those specified by user
  if (rt$rw > 0) {
    rt$use_breakpoints <- TRUE
  }
  
  if (!("mean" %in% names(rt$prior)  & "sd" %in% names(rt$prior))) {
    stop("prior must have both a mean and sd specified")
  }
  return(rt)
}

#' Back Calculation Options
#'
#'
#' @description Defines a list specifying the optional arguments for the back calculation
#' of cases. Only used if `rt = NULL`. 
#'  
#' @param smoothing_window Numeric, defaults to 7 days. The mean smoothing window to apply
#'   to mean shifted reports (used as a prior during back calculation). 7 days is the default
#'   as this smooths day of the week effects but depending on the quality of the data and the 
#'   amount of information users wish to use as a prior (higher values equalling a less 
#'   informative prior).
#' @return A list of back calculation settings
#' @export
#' @examples
#' # default settings
#' backcalc_opts()
backcalc_opts <- function(smoothing_window = 7) {
  backcalc <- list(
    smoothing_window = smoothing_window
  )
  return(backcalc)
}

#' Approximate Gaussian Process Settings
#'
#' @description Defines a list specifying the structure of the approximate Gaussian
#'  process. Custom settings can be supplied which override the defaults. 
#'  
#' @param ls_mean Numeric, defaults to 21 days. The mean of the lognormal length scale.
#' @param ls_sd Numeric, defaults to 7 days. The standard deviation of the log normal length 
#' scale with..
#' @param ls_max Numeric, defaults to 60. The maximum value of the length scale. Updated in 
#' `create_gp_data` to be the length of the input data if this is smaller.
#' @param ls_min Numeric, defaults to 3. The minimum value of the length scale.
#' @param alpha_sd Numeric, defaults to 0.1. The standard deviation of the magnitude parameter of
#' the Gaussian process kernel. Should be approximately the expected standard deviation of the logged Rt.
#' @param kernel Character string, the type of kernel required. Currently supporting the squared exponential 
#' kernel ("se") and the 3 over 2 Matern kernel ("matern", with `matern_type = 3/2`). Defaulting to the Matern 3 over 2 kernel as discontinuities are expected 
#' in Rt and infections.
#' @param matern_type Numeric, defaults to 3/2. Type of Matern Kernel to use. Currently only the Matern
#' 3/2 kernel is supported.
#' @param basis_prop Numeric, proportion of time points to use as basis functions. Decreasing this value 
#' results in a decrease in accuracy but a faster compute time. In general smaller posterior length scales 
#' require a higher proportion of basis functions. See (Riutort-Mayol et al. 2020 <https://arxiv.org/abs/2004.11408>) 
#' for advice on updating this default. This setting is an area of active research.
#' @param boundary_scale Numeric, boundary scale of the approximate Gaussian process. Defaults to 
#' 2. See (Riutort-Mayol et al. 2020 <https://arxiv.org/abs/2004.11408>) for advice on updating this 
#' default.
#' @param stationary Logical, defaults to `FALSE`. Should the Gaussian process be estimated with
#' a stationary global mean or be second order and so depend on the previous value. A stationary 
#' Gaussian process may be more tractable but will revert to the global average when data is 
#' sparse i.e for near real time estimates. This feature is experimental.
#' @return A list of settings defining the Gaussian process
#' @export
#' @examples
#' # default settings
#' gp_opts()
#' 
#' # add a custom length scale
#' gp_opts(ls_mean = 4)
gp_opts <- function(basis_prop = 0.3, 
                    boundary_scale = 2, 
                    ls_mean = 21, 
                    ls_sd = 7, 
                    ls_min = 3,
                    ls_max = 60,
                    alpha_sd = 0.1, 
                    kernel = "matern",
                    matern_type = 3/2,
                    stationary = FALSE) {
  gp <- list(
    basis_prop = basis_prop, 
    boundary_scale = boundary_scale, 
    ls_mean = ls_mean, 
    ls_sd = ls_sd, 
    ls_min = ls_min,
    ls_max = ls_max,
    alpha_sd = alpha_sd, 
    kernel = match.arg(kernel, choices = c("se", "matern_3/2")),
    matern_type = matern_type,
    stationary = stationary)
  
  
  if (gp$matern_type != 3/2) {
    stop("only the Matern 3/2 kernel is currently supported")
  }
  return(gp)
}

#' Observation Model Options
#'
#' @description Defines a list specifying the structure of the observation 
#' model. Custom settings can be supplied which override the defaults.
#' @param family Character string defining the observation model. Options are 
#' Negative binomial ("negbin"), the default, and Poisson.
#' @param weight Numeric, defaults to 1. Weight to give the observed data in
#'  the log density.
#' @param week_effect Logical defaulting to `TRUE`. Should a day of the week effect
#'  be used in the observation model.
#' @param scale List, defaulting to an empty list. Should an scaling factor be applied
#'  to map latent infections (convolved to date of report). If none empty a mean 
#'  (`mean`) and standard deviation (`sd`) needs to be supplied defining the normally
#'  distributed scaling factor.
#' @return A list of observation model settings.
#' @export
#' @examples
#' # default settings
#' obs_opts()
#' 
#' # Turn off day of the week effect
#' obs_opts(week_effect = TRUE)
#' 
#' # Scale reported data
#' obs_opts(scale = list(mean = 0.2, sd = 0.02))
obs_opts <- function(family = "negbin",
                     weight = 1,
                     week_effect = TRUE,
                     scale = list()) {
  obs <- list(
    family = match.arg(family, choices = c("poisson", "negbin")),
    weight = weight,
    week_effect = week_effect,
    scale = scale)
  
  if (length(obs$scale) != 0) {
    scale_names <- names(obs$scale)
    scale_correct <- "mean" %in% scale_names & "sd" %in% scale_names
    if (!scale_correct) {
      stop("If specifying a scale both a mean and sd are needed")
    }
  }
  return(obs)
}

#' Rstan Sampling Options
#'
#' @description Defines a list specifying the arguments passed to 
#' `rstan::sampling`. Custom settings can be supplied which override the defaults.
#' @param cores Numeric, number of cores to use in parallel. Defaults to 4 
#' if in interactive mode and otherwise 1.
#' @param warmup Numeric, defaults to 250. Number of warmup samples per chain.
#' @param samples Numeric, default 1000. Overall number of posterior samples. 
#' When using multiple chains iterations per chain is samples / chains.
#' @param chains Numeric, defaults to 4. Number of MCMC chains to use.
#' @param control List, defaults to empty. control parameters to pass to underlying
#' `rstan` function. By default `adapt_delta = 0.98` and `max_treedepth = 15` 
#' though these settings can be overwritten.
#' @param save_warmup Logical, defaults to FALSE. Should warmup progress be saved.
#' @param seed Numeric, defaults uniform random number between 1 and 1e8. Seed of 
#' sampling process.
#' @param future Logical, defaults to `FALSE`. Should stan chains be run in parallel
#' using `future`. This allows users to have chains fail gracefully (i.e when combined with 
#' `max_execution_time`). Should be combined with a call to `future::plan`
#' @param max_execution_time Numeric, defaults to Inf (seconds). If set will kill off
#' processing of each chain if not finished within the specified timeout. When more than 2 chains 
#' finish successfully estimates will still be returned. If less than 2 chains return within the
#' allowed time then estimation will fail with an informative error.
#' @param ... Additional parameters to pass to `rstan::sampling`.
#' @return A list of arguments to pass to `rstan::sampling`
#' @export
#' @examples
#' rstan_sampling_opts(samples = 2000)
rstan_sampling_opts <- function(cores = ifelse(interactive(), 4, 1),
                                warmup = 250,
                                samples = 1000,
                                chains = 4,
                                control = list(),
                                save_warmup = FALSE,
                                seed = as.integer(runif(1, 1, 1e8)),
                                future = FALSE,
                                max_execution_time = Inf,
                                ...) {
  
  opts <- list(
    cores = cores, 
    warmup = warmup,
    chains = chains,
    save_warmup = save_warmup,
    seed = seed,
    future = future,
    max_execution_time = max_execution_time
  )
  control_def <- list(adapt_delta = 0.98, max_treedepth = 15)
  opts$control <- update_defaults(control_def, control)
  opts$iter <- ceiling(samples / opts$chains) + opts$warmup
  opts <- c(opts, ...)
  return(opts)
}

#' Rstan Variational Bayes Options
#'
#' @description Defines a list specifying the arguments passed to 
#' `rstan::vb`. Custom settings can be supplied which override the defaults.
#' @param samples Numeric, default 1000. Overall number of approximate posterior 
#' samples.
#' @param trials Numeric, defaults to 10. Number of attempts to use `rstan::vb` 
#' before failing.
#' @param iter Numeric, defaulting to 10000. Number of iterations to use in 
#' `rtan::vb`.
#' @param ... Additional parameters to pass to `rstan::vb`.
#' @return A list of arguments to pass to `rstan::vb`
#' @export
#' @examples
#' rstan_vb_opts(samples = 2000)
rstan_vb_opts <- function(samples = 1000,
                          trials = 10,
                          iter = 10000, ...) {
  opts <- list(
    trials = trials,
    iter = iter, 
    output_samples = samples
  )
  opts <- c(opts, ...)
  return(opts)
}

#' Rstan Options
#'
#' @description Defines a list specifying the arguments passed to underlying `rstan`
#' functions via `rstan_sampling_opts` and `rstan_vb_opts`.Custom settings can be supplied
#'  which override the defaults.
#' @param object Stan model object. By default uses the compiled package default.
#' @param method A character string, defaulting to sampling. Currently supports
#' `rstan::sampling` ("sampling") or `rstan:vb` ("vb").
#' @param ... Additional parameters to pass  underlying option functions.
#' @return A list of arguments to pass to the appropriate rstan functions.
#' @export
#' @inheritParams rstan_sampling_opts
#' @seealso rstan_sampling_opts rstan_vb_opts
#' @examples
#' rstan_opts(samples = 2000)
#' 
#' # using vb
#' rstan_opts(method = "vb")
rstan_opts <- function(object = NULL,
                       samples = 1000,
                       method = "sampling", ...) {
  method <- match.arg(method, choices = c("sampling", "vb"))
  # shared everywhere opts
  if (is.null(object)) {
    object <- stanmodels$estimate_infections
  }
  opts <- list(
    object = object,
    method = method
  )
  if (method %in% "sampling") {
    opts <- c(opts, rstan_sampling_opts(samples = samples, ...))
  }else if (method %in% "vb") {
    opts <- c(opts, rstan_vb_opts(samples = samples, ...))
  }
  return(opts)
}

#' Stan Options
#'
#' @description Defines a list specifying the arguments passed to underlying stan
#' backend functions via `rstan_sampling_opts` and `rstan_vb_opts`. Custom settings
#' can be supplied which override the defaults.
#' @param backend Character string indicating the backend to use for fitting stan models.
#' Currently only "rstan" is supported.
#' @param return_fit Logical, defaults to TRUE. Should the fit stan model be returned.
#' @param ... Additional parameters to pass  underlying option functions.
#' @return A list of arguments to pass to the appropriate rstan functions.
#' @export
#' @inheritParams rstan_opts
#' @seealso rstan_opts 
#' @examples
#' # using default of rstan::sampling
#' stan_opts(samples = 2000)
#' 
#' # using vb
#' stan_opts(method = "vb")
stan_opts <- function(samples = 1000,
                      backend = "rstan", 
                      return_fit = TRUE,
                      ...){
  backend <- match.arg(backend, choices = c("rstan"))
  if (backend %in% "rstan") {
    opts <- rstan_opts(samples = samples,
                       ...)
  }
  opts <- c(opts, list(return_fit = return_fit))
  return(opts)
}