#' Map a plan position indicator (\code{ppi})
#'
#' Plot a ppi on a Google Maps, OpenStreetMap, Stamen Maps or Naver Map base
#' layer map using \link[ggmap]{ggmap}
#'
#' @param x An object of class \code{ppi}.
#' @param map  The basemap to use, result of a call to \link{download_basemap}.
#' @param param The scan parameter to plot.
#' @param alpha Transparency of the data, value between 0 and 1.
#' @param radar_size Size of the symbol indicating the radar position.
#' @param radar_color Colour of the symbol indicating the radar position.
#' @param n_color The number of colors (>=1) to be in the palette.
#' @param xlim Range of x values to plot (degrees longitude), as atomic
#' vector of length 2.
#' @param ylim Range of y values to plot (degrees latitude), as an atomic
#' vector of length 2.
#' @param zlim The range of values to plot.
#' @param ratio Aspect ratio between x and y scale, by default
#' \eqn{1/cos(latitude radar * pi/180)}.
#' @param ... Arguments passed to low level \link[ggmap]{ggmap} function.
#' @param radar.size Deprecated argument, use radar_size instead.
#' @param radar.color Deprecated argument, use radar_color instead.
#' @param n.color Deprecated argument, use n_color instead.
#'
#' @return A ggmap object (a classed raster object with a bounding
#' box attribute).
#'
#' @details
#' Available scan parameters for mapping can by printed to screen by
#' \code{summary(x)}. Commonly available parameters are:
#' \describe{
#'  \item{"\code{DBZH}", "\code{DBZ}"}{(Logged) reflectivity factor [dBZ]}
#'  \item{"\code{VRADH}", "\code{VRAD}"}{Radial velocity [m/s]. Radial
#'  velocities towards the radar are negative, while radial velocities away
#'  from the radar are positive}
#'  \item{"\code{RHOHV}"}{Correlation coefficient [unitless]. Correlation
#'  between vertically polarized and horizontally polarized reflectivity factor}
#'  \item{"\code{PHIDP}"}{Differential phase [degrees]}
#'  \item{"\code{ZDR}"}{(Logged) differential reflectivity [dB]}
#' }
#' The scan parameters are named according to the OPERA data information
#' model (ODIM), see Table 16 in the
#' \href{https://github.com/adokter/vol2bird/blob/master/doc/OPERA2014_O4_ODIM_H5-v2.2.pdf}{ODIM specification}.
#'
#' @export
#'
#' @examples
#' # load an example scan:
#' data(example_scan)
#' # make ppi's for all scan parameters in the scan
#' ppi <- project_as_ppi(example_scan)
#' # grab a basemap that matches the extent of the ppi:
#' \dontrun{basemap <- download_basemap(ppi)}
#' # map the radial velocity scan parameter onto the basemap:
#' \dontrun{map(ppi, map = basemap, param = "VRADH")}
#' # extend the plotting range of velocities, from -50 to 50 m/s:
#' \dontrun{map(ppi, map = basemap, param = "VRADH", zlim = c(-50, 50))}
#' # give the data less transparency:
#' \dontrun{map(ppi, map = basemap, alpha = 0.9)}
#' # change the appearance of the symbol indicating the radar location:
#' \dontrun{map(ppi, map = basemap, radar_size = 5, radar_color = "green")}
#' # crop the map:
#' \dontrun{map(ppi, map = basemap, xlim = c(12.4, 13.2), ylim = c(56, 56.5))}
map <- function(x, ...) {
  UseMethod("map", x)
}

#' @describeIn map plot a 'ppi' object on a map
#' @export
map.ppi <- function(x, map, param, alpha = 0.7, xlim, ylim,
                    zlim = c(-20, 20), ratio, radar_size = 3,
                    radar_color = "red", n_color = 1000,
                    radar.size = 3, radar.color = "red", n.color = 1000, ...) {

  # deprecate function arguments
  if (!missing(radar.size)) {
    warning("argument radar.size is deprecated; please use radar_size instead.",
      call. = FALSE
    )
    radar_size <- radar.size
  }
  if (!missing(radar.color)) {
    warning("argument radar.color is deprecated; please use radar_color instead.",
      call. = FALSE
    )
    radar_color <- radar.color
  }
  if (!missing(n.color)) {
    warning("argument n.color is deprecated; please use n_color instead.",
      call. = FALSE
    )
    n_color <- n.color
  }

  stopifnot(inherits(x, "ppi"))

  if (missing(param)) {
    if ("DBZH" %in% names(x$data)) {
      param <- "DBZH"
    } else {
      param <- names(x$data)[1]
    }
  } else if (!is.character(param)) {
    stop(
      "'param' should be a character string with a valid ",
      "scan parameter name."
    )
  }
  if (missing(zlim)) {
    zlim <- get_zlim(param)
  }
  if (!(param %in% names(x$data))) {
    stop(paste("no scan parameter '", param, "' in this ppi", sep = ""))
  }
  if (!attributes(map)$ppi) {
    stop("Not a ppi map, use download_basemap() to download a map.")
  }
  if (attributes(map)$geo$lat != x$geo$lat ||
    attributes(map)$geo$lon != x$geo$lon) {
    stop("Not a basemap for this radar location.")
  }

  # extract the scan parameter
  data <- do.call(function(y) x$data[y], list(param))
  wgs84 <- CRS("+proj=longlat +datum=WGS84")
  epsg3857 <- CRS("+init=epsg:3857") # this is the google mercator projection
  mybbox <- suppressWarnings(
    spTransform(
      SpatialPoints(t(data@bbox),
        proj4string = data@proj4string
      ),
      CRS("+init=epsg:3857")
    )
  )
  mybbox.wgs <- suppressWarnings(
    spTransform(
      SpatialPoints(t(data@bbox),
        proj4string = data@proj4string
      ),
      wgs84
    )
  )
  e <- raster::extent(mybbox.wgs)
  r <- raster(raster::extent(mybbox),
    ncol = data@grid@cells.dim[1] * .9,
    nrow = data@grid@cells.dim[2] * .9, crs = CRS(proj4string(mybbox))
  )

  # convert to google earth mercator projection
  data <- suppressWarnings(
    as.data.frame(spTransform(data, CRS("+init=epsg:3857")))
  )
  # bring z-values within plotting range
  index <- which(data$z < zlim[1])
  if (length(index) > 0) {
    data[index, ]$z <- zlim[1]
  }
  index <- which(data$z > zlim[2])
  if (length(index) > 0) {
    data[index, ]$z <- zlim[2]
  }

  # rasterize
  r <- raster::rasterize(data[, 2:3], r, data[, 1])
  # assign colors
  if (param %in% c("VRADH", "VRADV", "VRAD")) {
    cols <- add_color_transparency(
      colorRampPalette(
        colors = c("blue", "white", "red"),
        alpha = TRUE
      )(n_color),
      alpha = alpha
    )
  } else {
    cols <- add_color_transparency(
      colorRampPalette(
        colors = c(
          "lightblue", "darkblue", "green",
          "yellow", "red", "magenta"
        ),
        alpha = TRUE
      )(n_color),
      alpha = alpha
    )
  }

  col_func <- function(value, lim) {
    output <- rep(0, length(value))
    output <- round((value - lim[1]) / (lim[2] - lim[1]) * n_color)
    output[output > n_color] <- n_color
    output[output < 1] <- 1
    return(cols[output])
  }

  r@data@values <- col_func(r@data@values, zlim)
  # these declarations prevent generation of NOTE "no visible binding for
  # global variable" during package Check
  lon <- lat <- y <- z <- NA
  # symbols for the radar position
  # dummy is a hack to be able to include the ggplot2 color scale,
  # radarpoint is the actual plotting of radar positions.
  dummy <- geom_point(aes(x = lon, y = lat, colour = z),
    size = 0,
    data = data.frame(
      lon = x$geo$lon,
      lat = x$geo$lat,
      z = 0
    )
  )
  radarpoint <- geom_point(aes(x = lon, y = lat),
    colour = radar_color,
    size = radar_size,
    data = data.frame(lon = x$geo$lon, lat = x$geo$lat)
  )
  # colorscale
  colorscale <- color_scale(param, zlim)
  # bounding box
  bboxlatlon <- attributes(map)$geo$bbox
  # remove dimnames, otherwise ggmap will give a warning message below:
  dimnames(bboxlatlon) <- NULL
  if (missing(xlim)) xlim <- bboxlatlon[1, ]
  if (missing(ylim)) ylim <- bboxlatlon[2, ]
  # plot the data on the map
  mymap <- suppressMessages(
    ggmap(map) +
      inset_raster(raster::as.matrix(r), e@xmin, e@xmax, e@ymin, e@ymax) +
      dummy + colorscale +
      radarpoint +
      scale_x_continuous(limits = xlim, expand = c(0, 0)) +
      scale_y_continuous(limits = ylim, expand = c(0, 0))
  )
  suppressWarnings(mymap)
}


get_zlim <- function(param) {
  if (param %in% c("DBZH", "DBZV", "DBZ")) return(c(-20, 30))
  if (param %in% c("VRADH", "VRADV", "VRAD")) return(c(-20, 20))
  if (param == "RHOHV") return(c(0.4, 1))
  if (param == "ZDR") return(c(-5, 8))
  if (param == "PHIDP") return(c(-200, 200))
}
