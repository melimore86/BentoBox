#' Plot a rectangle within a BentoBox layout
#'
#' @usage
#' bb_plotRect(x, y, width, height,
#'             just = "center",
#'             default.units = "inches")
#'
#' @param x A numeric vector or unit object specifying rectangle x-locations.
#' @param y A numeric vector or unit object specifying rectangle y-locations.
#' @param width A numeric vector or unit object specifying rectangle widths.
#' @param height A numeric vector or unit object specifying rectangle heights.
#' @param just Justification of rectangle relative to its (x, y) location. If there are two values, the first value specifies horizontal justification and the second value specifies vertical justification.
#' Possible string values are: \code{"left"}, \code{"right"}, \code{"centre"}, \code{"center"}, \code{"bottom"}, and \code{"top"}. Default value is \code{just = "center"}.
#' @param default.units A string indicating the default units to use if \code{x}, \code{y}, \code{width}, and \code{height} are only given as numerics or numeric vectors. Default value is \code{default.units = "inches"}.
#' @param linecolor A character value specifying rectangle line color. Default value is \code{linecolor = "black"}.
#' @param lwd A numeric specifying rectangle line width. Default value is \code{lwd = 1}.
#' @param lty A numeric specifying rectangle line type. Default value is \code{lty = 1}.
#' @param fill A character value specifying rectangle fill color. Default value is \code{fill = NA}.
#' @param alpha Numeric value specifying color transparency. Default value is \code{alpha = 1}.
#' @param params An optional \link[BentoBox]{bb_assembly} object containing relevant function parameters.
#' @param ... Additional grid graphical parameters. See \link[grid]{gpar}.
#'
#' @return Returns a \code{bb_rect} object containing relevant placement and \link[grid]{grob} information.
#'
#' @examples
#' ## Create a BentoBox page
#' bb_pageCreate(width = 2, height = 2, default.units = "inches", xgrid = 0, ygrid = 0)
#'
#' ## Plot a rectangle
#' bb_plotRect(x = 1, y = 1, width = 0.75, height = 0.25, just = "center", default.units = "inches")
#'
#' @seealso \link[grid]{grid.rect}
#'
#' @export
bb_plotRect <- function(x, y, width, height, just = "center", default.units = "inches", linecolor = "black", lwd = 1, lty = 1, fill = NA, alpha = 1, params = NULL, ...){


  # ======================================================================================================================================================================================
  # PARSE PARAMETERS
  # ======================================================================================================================================================================================

  ## Check which defaults are not overwritten and set to NULL
  if(missing(just)) just <- NULL
  if(missing(linecolor)) linecolor <- NULL
  if(missing(fill)) fill <- NULL
  if(missing(lwd)) lwd <- NULL
  if(missing(lty)) lty <- NULL
  if(missing(alpha)) alpha <- NULL
  if(missing(default.units)) default.units <- NULL

  ## Check if label/x/y arguments are missing (could be in object)
  if(!hasArg(x)) x <- NULL
  if(!hasArg(y)) y <- NULL
  if(!hasArg(width)) width <- NULL
  if(!hasArg(height)) height <- NULL

  ## Compile all parameters into an internal object
  bb_rectInternal <- structure(list(x = x, y = y, width = width, height = height, just = just, linecolor = linecolor, fill = fill,
                                      lwd = lwd, lty = lty, alpha = alpha, default.units = default.units), class = "bb_rectInternal")

  bb_rectInternal <- parseParams(bb_params = params, object_params = bb_rectInternal)

  ## For any defaults that are still NULL, set back to default
  if(is.null(bb_rectInternal$just)) bb_rectInternal$just <- "center"
  if(is.null(bb_rectInternal$linecolor)) bb_rectInternal$linecolor <- "black"
  if(is.null(bb_rectInternal$fill)) bb_rectInternal$fill <- NA
  if(is.null(bb_rectInternal$lwd)) bb_rectInternal$lwd <- 1
  if(is.null(bb_rectInternal$lty)) bb_rectInternal$lty <- 1
  if(is.null(bb_rectInternal$alpha)) bb_rectInternal$alpha <- 1
  if(is.null(bb_rectInternal$default.units)) bb_rectInternal$default.units <- "inches"

  # ======================================================================================================================================================================================
  # INITIALIZE OBJECT
  # ======================================================================================================================================================================================

  bb_rect <- structure(list(x = bb_rectInternal$x, y = bb_rectInternal$y, width = bb_rectInternal$width, height = bb_rectInternal$height, just = bb_rectInternal$just,
                            grobs = NULL, gp = gpar(col = bb_rectInternal$linecolor, fill = bb_rectInternal$fill, lwd = bb_rectInternal$lwd, lty = bb_rectInternal$lty,
                                                    alpha = bb_rectInternal$alpha, ...)), class = "bb_rect")

  # ======================================================================================================================================================================================
  # CATCH ERRORS
  # ======================================================================================================================================================================================

  check_bbpage(error = "Cannot plot rectangle without a BentoBox page.")
  if(is.null(bb_rect$x)) stop("argument \"x\" is missing, with no default.", call. = FALSE)
  if(is.null(bb_rect$y)) stop("argument \"y\" is missing, with no default.", call. = FALSE)
  if(is.null(bb_rect$width)) stop("argument \"width\" is missing, with no default.", call. = FALSE)
  if(is.null(bb_rect$height)) stop("argument \"height\" is missing, with no default.", call. = FALSE)


  # ======================================================================================================================================================================================
  # DEFINE PARAMETERS
  # ======================================================================================================================================================================================

  ## Get page_height and its units from bbEnv through bb_makepage
  page_height <- get("page_height", envir = bbEnv)
  page_units <- get("page_units", envir = bbEnv)

  if (!"unit" %in% class(bb_rect$x)){

    if (!is.numeric(bb_rect$x)){

      stop("x-coordinate is neither a unit object or a numeric value. Cannot plot rectangle.", call. = FALSE)

    }

    if (is.null(bb_rectInternal$default.units)){

      stop("x-coordinate detected as numeric.\'default.units\' must be specified.", call. = FALSE)

    }

    bb_rect$x <- unit(bb_rect$x, bb_rectInternal$default.units)

  }

  if (!"unit" %in% class(bb_rect$y)){

    if (!is.numeric(bb_rect$y)){

      stop("y-coordinate is neither a unit object or a numeric value. Cannot plot rectangle.", call. = FALSE)

    }

    if (is.null(bb_rectInternal$default.units)){

      stop("y-coordinate detected as numeric.\'default.units\' must be specified.", call. = FALSE)

    }

    bb_rect$y <- unit(bb_rect$y, bb_rectInternal$default.units)

  }

  ## Convert coordinates to page_units
  new_x <- convertX(bb_rect$x, unitTo = page_units, valueOnly = TRUE)
  new_y <- convertY(bb_rect$y, unitTo = page_units, valueOnly = TRUE)

  # ======================================================================================================================================================================================
  # MAKE GROB
  # ======================================================================================================================================================================================

  rect <- grid.rect(x = unit(new_x, page_units), y = unit(page_height - new_y, page_units), width = bb_rect$width, height = bb_rect$height,
                        just = bb_rect$just, gp = bb_rect$gp)

  # ======================================================================================================================================================================================
  # ADD GROB TO OBJECT
  # ======================================================================================================================================================================================

  bb_rect$grobs <- rect

  # ======================================================================================================================================================================================
  # RETURN OBJECT
  # ======================================================================================================================================================================================

  return(bb_rect)
}



