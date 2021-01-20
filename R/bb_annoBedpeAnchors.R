#' annotates vertical boxes at anchors of bedpe elements
#'
#' @param plot bedpe plot to highlight bedpe anchors
#' @param x A numeric or unit object specifying x-location.
#' @param y A numeric or unit object specifying y-location.
#' @param height A numeric or unit object specifying height.
#' @param params an optional "bb_params" object space containing relevant function parameters
#' @param fillcolor character value specifying fillcolor of boxes
#' @param linecolor character value specifying linecolor of boxes
#' @param alpha numeric value specifying transparency
#' @param just justification of text relative to its (x, y) location
#' @param default.units A string indicating the default units to use if x or y are only given as numerics.

#' @export

bb_annoBedpeAnchors <- function(plot, x, y, height, params = NULL, fillcolor = "lightgrey", linecolor = NA, alpha = 0.4, just = c("left", "top"), default.units = "inches"){

  # ======================================================================================================================================================================================
  # FUNCTIONS
  # ======================================================================================================================================================================================

  bb_errorcheck_annoBedpeAnchors <- function(plot){

    if (!"bedpe" %in% names(plot)){
      stop("Cannot annotate bedpe anchors of a plot that does not use bedpe data.", call. = FALSE)
    }

  }

  # ======================================================================================================================================================================================
  # PARSE PARAMETERS
  # ======================================================================================================================================================================================
  ## Check which defaults are not overwritten and set to NULL
  if(missing(fillcolor)) fillcolor <- NULL
  if(missing(linecolor)) linecolor <- NULL
  if(missing(alpha)) alpha <- NULL
  if(missing(just)) just <- NULL
  if(missing(default.units)) default.units <- NULL

  ## Check if arguments are missing (could be in object)
  if(!hasArg(plot)) plot <- NULL
  if(!hasArg(x)) x <- NULL
  if(!hasArg(y)) y <- NULL
  if(!hasArg(height)) height <- NULL

  ## Compile all parameters into an internal object
  bb_bedpeHighlightInternal <- structure(list(plot = plot, x = x, y = y, height = height, fillcolor = fillcolor, linecolor = linecolor, alpha = alpha,
                                              just = just, default.units = default.units), class = "bb_bedpeHighlightInternal")

  bb_bedpeHighlightInternal <- parseParams(bb_params = params, object_params = bb_bedpeHighlightInternal)


  ## For any defaults that are still NULL, set back to default
  if(is.null(bb_bedpeHighlightInternal$fillcolor)) bb_bedpeHighlightInternal$fillcolor <- "lightgrey"
  if(is.null(bb_bedpeHighlightInternal$linecolor)) bb_bedpeHighlightInternal$linecolor <- NA
  if(is.null(bb_bedpeHighlightInternal$alpha)) bb_bedpeHighlightInternal$alpha <- 0.4
  if(is.null(bb_bedpeHighlightInternal$just)) bb_bedpeHighlightInternal$just <- c("left", "top")
  if(is.null(bb_bedpeHighlightInternal$default.units)) bb_bedpeHighlightInternal$default.units <- "inches"

  # ======================================================================================================================================================================================
  # INITIALIZE OBJECT
  # ======================================================================================================================================================================================

  bb_bedpeAnchor <- structure(list(chrom = plot$chrom, chromstart = plot$chromstart, chromend = plot$chromend,
                                   assembly = plot$assembly, x = bb_bedpeHighlightInternal$x, y = bb_bedpeHighlightInternal$y,
                                   width = plot$width, height = bb_bedpeHighlightInternal$height, just = bb_bedpeHighlightInternal$just, grobs = NULL,
                                   gp = gpar(fill = bb_bedpeHighlightInternal$fillcolor, col = bb_bedpeHighlightInternal$linecolor)), class = "bb_bedpeAnchor")

  # ======================================================================================================================================================================================
  # CHECK ERROS
  # ======================================================================================================================================================================================
  check_bbpage(error = "Cannot annotate bedpe anchors without a BentoBox page.")
  if(is.null(bb_bedpeHighlightInternal$plot)) stop("argument \"plot\" is missing, with no default.", call. = FALSE)
  if(is.null(bb_bedpeHighlightInternal$y)) stop("argument \"y\" is missing, with no default.", call. = FALSE)
  if(is.null(bb_bedpeHighlightInternal$height)) stop("argument \"height\" is missing, with no default.", call. = FALSE)

  bb_errorcheck_annoBedpeAnchors(plot = bb_bedpeHighlightInternal$plot)
  # ======================================================================================================================================================================================
  # PARSE UNITS
  # ======================================================================================================================================================================================

  if (!"unit" %in% class(bb_bedpeAnchor$x)){

    if (!is.numeric(bb_bedpeAnchor$x)){

      stop("x-coordinate is neither a unit object or a numeric value. Cannot place object.", call. = FALSE)

    }

    if (is.null(bb_bedpeHighlightInternal$default.units)){

      stop("x-coordinate detected as numeric.\'default.units\' must be specified.", call. = FALSE)

    }

    bb_bedpeAnchor$x <- unit(bb_bedpeAnchor$x, bb_bedpeHighlightInternal$default.units)

  }


  if (!"unit" %in% class(bb_bedpeAnchor$y)){

    if (!is.numeric(bb_bedpeAnchor$y)){

      stop("y-coordinate is neither a unit object or a numeric value. Cannot place object.", call. = FALSE)

    }

    if (is.null(bb_bedpeHighlightInternal$default.units)){

      stop("y-coordinate detected as numeric.\'default.units\' must be specified.", call. = FALSE)

    }

    bb_bedpeAnchor$y <- unit(bb_bedpeAnchor$y, bb_bedpeHighlightInternal$default.units)

  }

  if (!"unit" %in% class(bb_bedpeAnchor$height)){

    if (!is.numeric(bb_bedpeAnchor$height)){

      stop("Height is neither a unit object or a numeric value. Cannot place object.", call. = FALSE)

    }

    if (is.null(bb_bedpeHighlightInternal$default.units)){

      stop("Height detected as numeric.\'default.units\' must be specified.", call. = FALSE)

    }

    bb_bedpeAnchor$height <- unit(bb_bedpeAnchor$height, bb_bedpeHighlightInternal$default.units)

  }

  # ======================================================================================================================================================================================
  # VIEWPORTS
  # ======================================================================================================================================================================================
  ## Name viewport
  currentViewports <- current_viewports()
  vp_name <- paste0("bb_bedpeAnchor", length(grep(pattern = "bb_bedpeAnchor", x = currentViewports)) + 1)

  ## Convert coordinates into same units as page
  page_coords <- convert_page(object = bb_bedpeAnchor)

  vp <- viewport(height = page_coords$height, width = page_coords$width,
                 x = page_coords$x, y = page_coords$y,
                 clip = "on",
                 xscale = bb_bedpeHighlightInternal$plot$grobs$vp$xscale,
                 just = bb_bedpeHighlightInternal$just,
                 name = vp_name)

  # ======================================================================================================================================================================================
  # GROBS
  # ======================================================================================================================================================================================
  ## Get data from input bedpe object
  bedpe <- bb_bedpeHighlightInternal$plot$bedpe

  if (nrow(bedpe) > 0){
    ## Add loop shading from each anchor
    anchor1 <- grid.rect(x = unit(bedpe[[2]], "native"), y = 0,
                            width = unit(bedpe[[3]]-bedpe[[2]], "native"), height = 1, just = c("left", "bottom"),
                            gp = gpar(col = bb_bedpeHighlightInternal$linecolor, fill = bb_bedpeHighlightInternal$fillcolor, alpha = bb_bedpeHighlightInternal$alpha), vp = vp)

    anchor2 <- grid.rect(x = unit(bedpe[[5]], "native"), y = 0,
                            width = unit(bedpe[[6]]-bedpe[[5]], "native"), height = 1, just = c("left", "bottom"),
                            gp = gpar(col = bb_bedpeHighlightInternal$linecolor, fill = bb_bedpeHighlightInternal$fillcolor, alpha = bb_bedpeHighlightInternal$alpha), vp = vp)
    bedpeAnchor_grobs <- gTree(vp = vp, children = gList(anchor1, anchor2))
    bb_bedpeAnchor$grobs <- bedpeAnchor_grobs
  } else {
    warning("No bedpe elements found in region.", call. = FALSE)
  }

  # ======================================================================================================================================================================================
  # RETURN OBJECT
  # ======================================================================================================================================================================================

  return(bb_bedpeAnchor)

}