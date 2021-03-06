#' Plot similarity between seed words
#' @param x fitted textmodel_lss object
#' @param group if `TRUE` group seed words by seed patterns and show
#'   average similarity
#' @export
textplot_simil <- function(x, group = FALSE) {
    UseMethod("textplot_simil")
}

#' @method textplot_simil textmodel_lss
#' @import ggplot2
#' @export
textplot_simil.textmodel_lss <- function(x, group = FALSE) {

    if (is.null(x$similarity) || is.null(x$seeds_weighted))
        stop("textplot_simil() does not work with dummy models")

    temp <- reshape2::melt(x$similarity, as.is = TRUE)
    names(temp) <- c("seed1", "seed2", "simil")
    if (group) {
        seed <- rep(names(x$seeds_weighted), lengths(x$seeds_weighted))
        names(seed) <- names(unlist(unname(x$seeds_weighted)))
        temp$seed1 <- seed[temp$seed1]
        temp$seed2 <- seed[temp$seed2]
        temp <- stats::aggregate(list(simil = temp$simil),
                                 by = list(seed1 = temp$seed1,
                                           seed2 = temp$seed2), mean)
    }
    temp$seed1 <- factor(temp$seed1, levels = unique(temp$seed2))
    temp$seed2 <- factor(temp$seed2, levels = unique(temp$seed2))
    temp$color <- factor(temp$simil > 0, levels = c(TRUE, FALSE),
                         labels = c("positive", "negative"))
    temp$size <- abs(temp$simil)
    seed1 <- seed2 <- simil <- size <- color <- NULL
    ggplot(data = temp, aes(x = seed1, y = seed2)) +
        geom_point(aes(colour = color, cex = size)) +
        guides(cex = guide_legend(order = 1),
               colour = guide_legend(order = 2)) +
        theme(axis.title.x = element_blank(),
              axis.title.y = element_blank(),
              axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))
}

#' @export
#' @importFrom quanteda.textmodels textplot_scale1d
quanteda.textmodels::textplot_scale1d

#' @method textplot_scale1d textmodel_lss
#' @export
#' @noRd
#' @import ggplot2
textplot_scale1d.textmodel_lss <- function(x,
                                           margin = c("features", "documents"),
                                           doclabels = NULL,
                                           sort = TRUE,
                                           groups = NULL,
                                           highlighted = NULL,
                                           alpha = 0.7,
                                           highlighted_color = "black") {
    .Deprecated("textplot_terms")
    margin <- match.arg(margin)
    if (margin == "documents") {
        stop("There is no document margin in a LSS model.")
    } else if (margin == "features") {
        textplot_scale1d_features(
            x$beta,
            weight = log(x$frequency),
            featlabels = names(x$beta),
            highlighted = highlighted,
            alpha = alpha,
            highlighted_color = highlighted_color)
    }
}

#' Internal function adopted from quanteda
#' @noRd
#' @import ggplot2
#' @keywords internal
textplot_scale1d_features <- function(x, weight, featlabels,
                                      highlighted = NULL, alpha = 0.7,
                                      highlighted_color = "black") {

    beta <- psi <- feature <- NULL
    temp <- data.frame(feature = featlabels,
                       psi = weight,
                       beta = x)
    ggplot(data = temp, aes(x = beta, y = psi, label = feature)) +
        geom_text(colour = "grey70", alpha = alpha) +
        geom_text(aes(beta, psi, label = feature),
                  data = temp[temp$feature %in% highlighted,],
                  color = highlighted_color) +
        xlab("beta") +
        ylab("log(term frequency)") +
        theme_bw() +
        theme(panel.background = ggplot2::element_blank(),
              panel.grid.major.x = element_blank(),
              panel.grid.minor.x = element_blank(),
              # panel.grid.major.y = element_blank(),
              panel.grid.minor.y = element_blank(),
              plot.background = element_blank(),
              axis.ticks.y = element_blank(),
              # panel.spacing = grid::unit(0.1, "lines"),
              panel.grid.major.y = element_line(linetype = "dotted"))
}

#' Plot polarity scores of words
#' @param x fitted textmodel_lss object
#' @param highlighted [quanteda::pattern] to specify words to highlight
#' @export
textplot_terms <- function(x, highlighted = NULL) {
    UseMethod("textplot_terms")
}

#' @method textplot_terms textmodel_lss
#' @import ggplot2 ggrepel stringi
#' @export
textplot_terms.textmodel_lss <- function(x, highlighted = NULL) {

    if (is.null(highlighted))
        highlighted <- character()
    if (is.dictionary(highlighted)) {
        separator <- meta(highlighted, field = "separator", type = "object")
        valuetype <- meta(highlighted, field = "valuetype", type = "object")
        concatenator <- x$concatenator
        highlighted <- unlist(highlighted, use.names = FALSE)
        if (!nzchar(separator) && !is.null(concatenator)) # for backward compatibility
            highlighted <- stri_replace_all_fixed(highlighted, separator, concatenator)
    } else {
        highlighted <- unlist(highlighted, use.names = FALSE)
        valuetype <- "glob"
    }
    words_hl <- quanteda::pattern2fixed(
        highlighted,
        types = names(x$beta),
        valuetype = valuetype,
        case_insensitive = TRUE
    )

    beta <- frequency <- word <- NULL
    temp <- data.frame(word = names(x$beta), beta = x$beta, frequency = log(x$frequency),
                       stringsAsFactors = FALSE)
    is_hl <- temp$word %in% unlist(words_hl, use.names = FALSE)
    temp_black <- subset(temp, is_hl)
    temp_gray <- subset(temp, !is_hl)
    ggplot(data = temp_gray, aes(x = beta, y = frequency, label = word)) +
           geom_text(colour = "grey70", alpha = 0.7) +
           labs(x = "Polarity", y = "Frequency (log)") +
           theme_bw() +
           theme(panel.grid= element_blank(),
                 axis.title.x = element_text(margin = margin(t = 10, r = 0, b = 0, l = 0)),
                 axis.title.y = element_text(margin = margin(t = 0, r = 10, b = 0, l = 0))) +
           geom_text_repel(data = temp_black, aes(x = beta, y = frequency, label = word),
                           segment.size = 0.25, colour = "black") +
           geom_point(data = temp_black, aes(x = beta, y = frequency), cex = 0.7, colour = "black")

}
