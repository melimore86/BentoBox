#' Annotate DNA loops in a Hi-C plot
#'
#' @usage bb_annoLoops(hicPlot, bedpeData)
#'
#' @param hicPlot Hi-C plot object from \code{bb_plotHicSquare} or \code{bb_plotHicTriangle} on which to annotate loops.
#' @param bedpeData A string specifying the BEDPE file path or a dataframe in BEDPE format specifying loop positions.
#' @param type Character value specifying type of annotation. Default value is \code{type = "box"}. Options are:
#' \itemize{
#' \item{\code{"box"}: }{Boxes are drawn around each loop.}
#' \item{\code{"circle"}: }{Circles are drawn around each loop.}
#' \item{\code{"arrow"}: }{Arrows are drawn pointing to each loop.}
#' }
#' @param half Character value specifying which half of hic plots to annotate. Triangle Hi-C plots will always default to the entirety of the triangular plot. Default value is \code{half = "inherit"}. Options are:
#' \itemize{
#' \item{\code{"inherit"}: }{Loops will be annotated on the \code{half} inherited by the input Hi-C plot.}
#' \item{\code{"both"}: }{Loops will be annotated on both halves of the diagonal of a square Hi-C plot.}
#' \item{\code{"top"}: }{Loops will be annotated on the upper diagonal half of a square Hi-C plot.}
#' \item{\code{"bottom"}: }{Loops will be annotated ont the bottom diagonal half of a square Hi-C plot.}
#' }
#' @param shift Numeric specifying the number of pixels on either end of loop in a box or circle. Numeric specifying number of pixels for the length of an arrow.
#' @param params An optional \link[BentoBox]{bb_assembly} object containing relevant function parameters.
#' @param ... Additional grid graphical parameters. See \link[grid]{gpar}.
#'
#' @return Returns a \code{bb_loops} object containing relevant genomic region, placement, and \link[grid]{grob} information.
#'
#' @examples
#' ## Load Hi-C data and BEDPE data
#' data("bb_hicData")
#' data("bb_bedpeData")
#'
#' ## Create BentoBox page
#' bb_pageCreate(width = 3, height = 3, default.units = "inches", xgrid = 0, ygrid = 0)
#'
#' ## Plot and place a square Hi-C plot
#' hicPlot <- bb_plotHicSquare(hicData = bb_hicData, resolution = 10000, zrange = c(0, 70),
#'                             chrom = "chr21", chromstart = 28000000, chromend = 30300000,
#'                             x = 0, y = 0, width = 3, height = 3, just = c("left", "top"), default.units = "inches")
#'
#' ## Annotate loops of Hi-C plot
#' bb_annoLoops(hicPlot = hicPlot, bedpeData = bb_bedpeData, type = "box", half = "both")
#'
#' @export
bb_annoLoops <- function(hicPlot, bedpeData, type = "box", half = "inherit", shift = 4, params = NULL, ...){

  # ======================================================================================================================================================================================
  # FUNCTIONS
  # ======================================================================================================================================================================================
  ## For more accurate calculation of sqrt(2)
  two <- mpfr(2, 120)

  ## Define a function to catch errors for bb_annoLoops
  errorcheck_bb_annoLoops <- function(hic, loops, half, type){

    ###### hic #####

    ## check type of input for hic
    if (!class(hic) %in% c("bb_hicSquare", "bb_hicTriangle" )){

      stop("Input plot must be a plot of class \'bb_hicSquare\' or \'bb_hicTriangle\'.", call. = FALSE)

    }

    ###### loops #####

    ## if loops is a dataframe or datatable, it needs to be properly formatted
    if ("data.frame" %in% class(loops) && ncol(loops) < 6){

      stop("Invalid dataframe format. Dataframe must be in BEDPE format.", call. = FALSE)

    }

    if ("data.frame" %in% class(loops) && nrow(loops) < 1){

      stop("Loop input contains no values.", call. = FALSE)

    }


    ## if it's a file path, it needs to exist
    if (!"data.frame" %in% class(loops)){

      # ## File extension
      # if (file_ext(loops) != "bedpe"){
      #
      #   stop("Invalid input. File must have a \".bedpe\" extension")
      #
      # }

      ## File existence
      if (!file.exists(loops)){

        stop(paste("File", loops, "does not exist."), call. = FALSE)

      }

    }

    ###### half #####

    ## half needs to be a valid option
    if (!half %in% c("inherit", "both", "top", "bottom")){

      stop("Invalid \'half\'.  Options are \'inherit\', \'both\', \'top\', or \'bottom\'.", call. = FALSE)

    }

    ## half needs to be able to align with what kind of hic plot is plotted
    if (class(hic) == "bb_hic"){

      if (is.null(hic$althalf)){

        if ((hic$half == "top" | hic$half == "bottom") && (half == "both")){

          stop("Invalid \'half\' of plot to annotate.", call. = FALSE)

        }

        if (hic$half == "top" & half == "bottom"){

          stop("Invalid \'half\' of plot to annotate.", call. = FALSE)

        }

        if (hic$half == "bottom" & half == "top"){

          stop("Invalid \'half\' of plot to annotate.", call. = FALSE)

        }

      } else {

        if (hic$althalf == "bottom"){

          message(paste("Attempting to annotate loops where", hic$chrom, "is on the x-axis and", hic$altchrom, "is on the y-axis."), call. = FALSE)

        } else if (hic$althalf == "top"){

          message(paste("Attempting to annotate loops where", hic$altchrom, "is on the x-axis and", hic$chrom, "is on the y-axis."), call. = FALSE)

        }

      }

    } else if (class(hic) == "bb_hicTriangle"){

      if (half == "both" | half == "bottom"){

        warning("Plot of class \'bb_hicTriangle\' detected.  Loops will automatically be annotated in the upper triangular of the plot.", call. = FALSE)

      }

    }

    ###### annotation #####

    ## Check type of annotation
    if (!type %in% c("box", "circle", "arrow")){

      stop("Invalid \'type\' of annotation.  Options are \'box\', \'circle\', or \'arrow\'.", call. = FALSE)

    }

  }

  ## Define a function that subsets loop data for hic region
  subset_loops <- function(hic, loops, object){

    ## chrom always in col1
    ## altchrom always in col4
    ## triangle hic plots will not have altchrom parameters
    if (class(hic) == "bb_hicTriangle"){
      loops_subset <- loops[which(loops[,1] == object$chrom & loops[,4] == object$chrom & loops[,2] >= object$chromstart & loops[,3] <= object$chromend
                                  & loops[,5] >= object$chromstart & loops[,6] <= object$chromend),]
    } else {
      loops_subset <- loops[which(loops[,1] == object$chrom & loops[,4] == object$altchrom & loops[,2] >= object$chromstart & loops[,3] <= object$chromend
                                  & loops[,5] >= object$altchromstart & loops[,6] <= object$altchromend),]
    }

    return(loops_subset)

  }

  ## Define a function that parses an inherited half
  inherit_half <- function(hic){

    if (class(hic) == "bb_hicSquare"){

      if (is.null(hic$althalf)){

        half <- hic$half

      } else {

        half <- hic$althalf

      }

    } else if (class(hic) == "bb_hicTriangle"){

      half <- "top"

    }

    return(half)

  }

  ## Define a function to add box annotation
  boxAnnotation <- function(df, hic, object, shift, half){

    side <- (as.numeric(df[6]) - as.numeric(df[5])) + (2 * shift * hic$resolution)

    if (half == "bottom"){

      center_x <- 0.5 * (as.numeric(df[5]) + as.numeric(df[6]))
      center_y <- 0.5 * (as.numeric(df[2]) + as.numeric(df[3]))
      rect1 <- rectGrob(x = center_x, y = center_y, width = side, height = side, default.units = "native",
                        gp = object$gp)

      assign("loop_grobs", addGrob(gTree = get("loop_grobs", envir = bbEnv), child = rect1), envir = bbEnv)

    } else if (half == "top"){

      center_x <- 0.5 * (as.numeric(df[2]) + as.numeric(df[3]))
      center_y <- 0.5 * (as.numeric(df[5]) + as.numeric(df[6]))
      rect1 <- rectGrob(x = center_x, y = center_y, width = side, height = side, default.units = "native",
                        gp = object$gp)

      assign("loop_grobs", addGrob(gTree = get("loop_grobs", envir = bbEnv), child = rect1), envir = bbEnv)

    } else if (half == "both"){

      ## BOTTOM
      center_x1 <- 0.5 * (as.numeric(df[5]) + as.numeric(df[6]))
      center_y1 <- 0.5 * (as.numeric(df[2]) + as.numeric(df[3]))

      ## TOP
      center_x2 <- 0.5 * (as.numeric(df[2]) + as.numeric(df[3]))
      center_y2 <- 0.5 * (as.numeric(df[5]) + as.numeric(df[6]))

      rect1 <- rectGrob(x = center_x1, y = center_y1, width = side, height = side, default.units = "native",
                        gp = object$gp)
      rect2 <- rectGrob(x = center_x2, y = center_y2, width = side, height = side, default.units = "native",
                        gp = object$gp)

      assign("loop_grobs", addGrob(gTree = get("loop_grobs", envir = bbEnv), child = rect1), envir = bbEnv)
      assign("loop_grobs", addGrob(gTree = get("loop_grobs", envir = bbEnv), child = rect2), envir = bbEnv)

    }

  }

  ## Define a function to add circle annotation
  circleAnnotation <- function(df, hic, object, shift, half){

    radius <- (0.5 * (as.numeric(df[6]) - as.numeric(df[5]))) + (shift * hic$resolution)

    if (half == "bottom"){

      center_x <- 0.5 * (as.numeric(df[5]) + as.numeric(df[6]))
      center_y <- 0.5 * (as.numeric(df[2]) + as.numeric(df[3]))
      circ1 <- circleGrob(x = center_x, y = center_y, r = radius, default.units = "native",
                          gp = object$gp)

      assign("loop_grobs", addGrob(gTree = get("loop_grobs", envir = bbEnv), child = circ1), envir = bbEnv)

    } else if (half == "top"){

      center_x <- 0.5 * (as.numeric(df[2]) + as.numeric(df[3]))
      center_y <- 0.5 * (as.numeric(df[5]) + as.numeric(df[6]))
      circ1 <- circleGrob(x = center_x, y = center_y, r = radius, default.units = "native",
                          gp = object$gp)

      assign("loop_grobs", addGrob(gTree = get("loop_grobs", envir = bbEnv), child = circ1), envir = bbEnv)

    } else if (half == "both"){

      ## BOTTOM
      center_x1 <- 0.5 * (as.numeric(df[5]) + as.numeric(df[6]))
      center_y1 <- 0.5 * (as.numeric(df[2]) + as.numeric(df[3]))

      ## TOP
      center_x2 <- 0.5 * (as.numeric(df[2]) + as.numeric(df[3]))
      center_y2 <- 0.5 * (as.numeric(df[5]) + as.numeric(df[6]))

      circ1 <- circleGrob(x = center_x1, y = center_y1, r = radius, default.units = "native",
                          gp = object$gp)
      circ2 <- circleGrob(x = center_x2, y = center_y2, r = radius, default.units = "native",
                          gp = object$gp)

      assign("loop_grobs", addGrob(gTree = get("loop_grobs", envir = bbEnv), child = circ1), envir = bbEnv)
      assign("loop_grobs", addGrob(gTree = get("loop_grobs", envir = bbEnv), child = circ2), envir = bbEnv)

    }

  }

  ## Define a function to add arrow annotation
  arrowAnnotation <- function(df, hic, object, shift, half){

    if (half == "bottom"){

     x0 <- as.numeric(df[6]) + (0.5 * (as.numeric(df[6]) - as.numeric(df[5])))
     y0 <- as.numeric(df[2]) - (0.5 * (as.numeric(df[6]) - as.numeric(df[5])))

     arrow1 <- segmentsGrob(x0 = x0, y0 = y0, x1 = x0 + (shift * hic$resolution), y1 = y0 - (shift * hic$resolution),
                   arrow = arrow(length = unit(0.1, "inches"), ends = "first", type = "closed"), default.units = "native",
                   gp = object$gp)

     assign("loop_grobs", addGrob(gTree = get("loop_grobs", envir = bbEnv), child = arrow1), envir = bbEnv)

    } else if (half == "top"){

      x0 <- as.numeric(df[2]) - (0.5 * (as.numeric(df[6]) - as.numeric(df[5])))
      y0 <- as.numeric(df[6]) + (0.5 * (as.numeric(df[6]) - as.numeric(df[5])))

      arrow1 <- segmentsGrob(x0 = x0, y0 = y0, x1 = x0 - (shift * hic$resolution), y1 = y0 + (shift * hic$resolution),
                    arrow = arrow(length = unit(0.1, "inches"), ends = "first", type = "closed"), default.units = "native",
                    gp = object$gp)

      assign("loop_grobs", addGrob(gTree = get("loop_grobs", envir = bbEnv), child = arrow1), envir = bbEnv)

    } else if (half == "both"){

      ## BOTTOM
      x01 <- as.numeric(df[6]) + (0.5 * (as.numeric(df[6]) - as.numeric(df[5])))
      y01 <- as.numeric(df[2]) - (0.5 * (as.numeric(df[6]) - as.numeric(df[5])))

      ## TOP
      x02 <- as.numeric(df[2]) - (0.5 * (as.numeric(df[6]) - as.numeric(df[5])))
      y02 <- as.numeric(df[6]) + (0.5 * (as.numeric(df[6]) - as.numeric(df[5])))

      arrow1 <- segmentsGrob(x0 = x01, y0 = y01, x1 = x01 + (shift * hic$resolution), y1 = y01 - (shift * hic$resolution),
                    arrow = arrow(length = unit(0.1, "inches"), ends = "first", type = "closed"), default.units = "native",
                    gp = object$gp)
      arrow2 <- segmentsGrob(x0 = x02, y0 = y02, x1 = x02 - (shift * hic$resolution), y1 = y02 + (shift * hic$resolution),
                    arrow = arrow(length = unit(0.1, "inches"), ends = "first", type = "closed"), default.units = "native",
                    gp = object$gp)

      assign("loop_grobs", addGrob(gTree = get("loop_grobs", envir = bbEnv), child = arrow1), envir = bbEnv)
      assign("loop_grobs", addGrob(gTree = get("loop_grobs", envir = bbEnv), child = arrow2), envir = bbEnv)

    }

  }

  # ======================================================================================================================================================================================
  # PARSE PARAMETERS
  # ======================================================================================================================================================================================

  ## Check which defaults are not overwritten and set to NULL
  if(missing(half)) half <- NULL
  if(missing(shift)) shift <- NULL
  if(missing(type)) type <- NULL

  ## Check if hic/loops arguments are missing (could be in object)
  if(!hasArg(hicPlot)) hicPlot <- NULL
  if(!hasArg(bedpeData)) bedpeData <- NULL

  ## Compile all parameters into an internal object
  bb_loopsInternal <- structure(list(hicPlot = hicPlot, bedpeData = bedpeData, half = half, shift = shift, type = type, gp = gpar(...)), class = "bb_loopsInternal")

  bb_loopsInternal <- parseParams(bb_params = params, object_params = bb_loopsInternal)

  ## For any defaults that are still NULL, set back to default
  if(is.null(bb_loopsInternal$half)) bb_loopsInternal$half <- "inherit"
  if(is.null(bb_loopsInternal$shift)) bb_loopsInternal$shift <- 4
  if(is.null(bb_loopsInternal$type)) bb_loopsInternal$type <- "box"

  # ======================================================================================================================================================================================
  # INITIALIZE OBJECT: GET REGION/DIMENSIONS FROM HIC PLOT INPUT
  # ======================================================================================================================================================================================

  bb_loops <- structure(list(chrom = bb_loopsInternal$hicPlot$chrom, chromstart = bb_loopsInternal$hicPlot$chromstart, chromend = bb_loopsInternal$hicPlot$chromend, altchrom = bb_loopsInternal$hicPlot$altchrom,
                             altchromstart = bb_loopsInternal$hicPlot$altchromstart, altchromend = bb_loopsInternal$hicPlot$altchromend, assembly = bb_loopsInternal$hicPlot$assembly,
                             x = bb_loopsInternal$hicPlot$x, y = bb_loopsInternal$hicPlot$y, width = bb_loopsInternal$hicPlot$width, height = bb_loopsInternal$hicPlot$height,
                             just = bb_loopsInternal$hicPlot$just, grobs = NULL), class = "bb_loops")

  # ======================================================================================================================================================================================
  # CATCH ERRORS
  # ======================================================================================================================================================================================

  check_bbpage(error = "Cannot annotate Hi-C loops without a BentoBox page.")
  if(is.null(bb_loopsInternal$hicPlot)) stop("argument \"hicPlot\" is missing, with no default.", call. = FALSE)
  if(is.null(bb_loopsInternal$bedpeData)) stop("argument \"bedpeData\" is missing, with no default.", call. = FALSE)


  errorcheck_bb_annoLoops(hic = bb_loopsInternal$hicPlot, loops = bb_loopsInternal$bedpeData,
                              half = bb_loopsInternal$half, type = bb_loopsInternal$type)

  # ======================================================================================================================================================================================
  # PARSE INHERITED HALF
  # ======================================================================================================================================================================================

  half <- bb_loopsInternal$half
  if (half == "inherit"){

    half <- inherit_half(hic = bb_loopsInternal$hicPlot)

  }

  if (class(bb_loopsInternal$hicPlot) == "bb_hicTriangle"){

    half <- "top"

  }

  # ======================================================================================================================================================================================
  # READ IN FILE OR DATAFRAME
  # ======================================================================================================================================================================================

  loops <- bb_loopsInternal$bedpeData
  if (!"data.frame" %in% class(loops)){

    loops <- as.data.frame(data.table::fread(loops))
    if (nrow(loops) < 1){
      warning("Loop input contains no values.", call. = FALSE)
    }


  }

  ## Check format of chromosomes in columns 1 and 4
  if (bb_loops$assembly$Genome == "hg19"){

    checkChr <- function(chr){
      return(grepl("chr", chr))
    }

    col1Checks <- unlist(lapply(loops[,1], checkChr))
    if (any(col1Checks == FALSE)){
      stop("Chromosomes in column 1 are in invalid format for hg19 genome assembly. Please specify chromosomes as a string with the following format: 'chr1'.", call. = FALSE)
    }
    col4Checks <- unlist(lapply(loops[,4], checkChr))
    if (any(col4Checks == FALSE)){
      stop("Chromosomes in column 4 are in invalid format for hg19 genome assembly. Please specify chromosomes as a string with the following format: 'chr1'.", call. = FALSE)
    }


  }

  # ======================================================================================================================================================================================
  # SUBSET FOR LOOPS IN REGION
  # ======================================================================================================================================================================================
  ## Assuming loops are in first six columns only
  loops <- loops[,1:6]

  loops_subset <- subset_loops(hic = bb_loopsInternal$hicPlot, loops = loops, object = bb_loops)

  # ======================================================================================================================================================================================
  # VIEWPORTS
  # ======================================================================================================================================================================================

  ## Name viewport
  currentViewports <- current_viewports()
  vp_name <- paste0("bb_loopAnnotation", length(grep(pattern = "bb_loopAnnotation", x = currentViewports)) + 1)

  ## Make viewport based on hic input viewport
  if (class(bb_loopsInternal$hicPlot) == "bb_hicSquare"){

    vp <- viewport(height = bb_loopsInternal$hicPlot$grobs$vp$height, width = bb_loopsInternal$hicPlot$grobs$vp$width,
                   x = bb_loopsInternal$hicPlot$grobs$vp$x, y = bb_loopsInternal$hicPlot$grobs$vp$y,
                   clip = "on",
                   xscale = bb_loopsInternal$hicPlot$grobs$vp$xscale,
                   yscale = bb_loopsInternal$hicPlot$grobs$vp$yscale,
                   just = bb_loopsInternal$hicPlot$grobs$vp$justification,
                   name = vp_name)
  } else if (class(bb_loopsInternal$hicPlot) == "bb_hicTriangle"){


    width <- convertUnit(bb_loopsInternal$hicPlot$outsideVP$width, unitTo = get("page_units", bbEnv), valueOnly = T)

    vp <- viewport(height = unit(width/sqrt(two), get("page_units", bbEnv)), width = unit(width/sqrt(two), get("page_units", bbEnv)),
                   x = bb_loopsInternal$hicPlot$outsideVP$x, y = bb_loopsInternal$hicPlot$outsideVP$y,
                   xscale = bb_loopsInternal$hicPlot$grobs$vp$xscale,
                   yscale = bb_loopsInternal$hicPlot$grobs$vp$yscale,
                   just = bb_loopsInternal$hicPlot$outsideVP$justification,
                   name = vp_name,
                   angle = -45)

  }


  # ======================================================================================================================================================================================
  # INITIALIZE GTREE OF GROBS
  # ======================================================================================================================================================================================

  assign("loop_grobs", gTree(vp = vp), envir = bbEnv)

  # ======================================================================================================================================================================================
  # PLOT
  # ======================================================================================================================================================================================

  if (nrow(loops_subset) > 0){

    if (bb_loopsInternal$type == "box"){

      bb_loopsInternal$gp$fill <- NA
      invisible(apply(loops_subset, 1, boxAnnotation, hic = bb_loopsInternal$hicPlot, object = bb_loopsInternal, shift = bb_loopsInternal$shift, half = half))

    } else if (bb_loopsInternal$type == "circle"){
      bb_loopsInternal$gp$fill <- NA
      invisible(apply(loops_subset, 1, circleAnnotation, hic = bb_loopsInternal$hicPlot, object = bb_loopsInternal, shift = bb_loopsInternal$shift, half = half))

    } else if (bb_loopsInternal$type == "arrow"){
      if (is.null(bb_loopsInternal$gp$col) & is.null(bb_loopsInternal$gp$fill)){
        bb_loopsInternal$gp$fill <- "black"
      } else {
        if(is.null(bb_loopsInternal$gp$fill)){
          bb_loopsInternal$gp$fill <- bb_loopsInternal$gp$col
        }
      }

      invisible(apply(loops_subset, 1, arrowAnnotation, hic = bb_loopsInternal$hicPlot, object = bb_loopsInternal, shift = bb_loopsInternal$shift, half = half))

    }

  } else {

    warning("No loops found in region.", call. = FALSE)
  }


  # ======================================================================================================================================================================================
  # ADD GROBS TO OBJECT
  # ======================================================================================================================================================================================

  bb_loops$grobs <- get("loop_grobs", envir = bbEnv)
  grid.draw(bb_loops$grobs)

  # ======================================================================================================================================================================================
  # RETURN OBJECT
  # ======================================================================================================================================================================================

  return(bb_loops)

}
