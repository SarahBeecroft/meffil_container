## Cord blood reference data generated by Kristina Gervin and Robert Lyle.

## Kristina Gervin <kristina.gervin@medisin.uio.no>
##     Robert Lyle <robert.lyle@ibv.uio.no>
    

create.gervin.lyle.reference <- function(data.dir, verbose=T) {
    number.pcs <- 8
    
    samplesheet <- meffil.read.samplesheet(data.dir, "csv$")
    
    ds <- meffil.normalize.dataset(
        samplesheet,
        just.beta=F,
        qc.file="gervin-and-lyle-qc-report.html",
        author="Kristina Gervin and Robert Lyle",
        study="Purified cord blood cell type methylation",
        number.pcs=number.pcs,
        norm.file="gervin-and-lyle-normalization-report.html",
        chip="450k",
        featureset="common",
        verbose=verbose)
    
    ## pc.plot <- meffil.plot.pc.fit(ds$norm.objects)
    ## suggests that number.pcs should be 8
    
    samplesheet <- samplesheet[match(colnames(ds$M), samplesheet$Sample_Name),]
    samplesheet$cell.type <- toupper(samplesheet$cellType)
    samplesheet$cell.type[which(samplesheet$cell.type == "CD19")] <- "Bcell"
    samplesheet$cell.type[which(samplesheet$cell.type == "GRAN")] <- "Gran"
    samplesheet$cell.type[which(samplesheet$cell.type == "CD4")] <- "CD4T"
    samplesheet$cell.type[which(samplesheet$cell.type == "CD8")] <- "CD8T"
    cell.types <- c("CD14", "Bcell", "CD4T", "CD8T", "NK","Gran")
    selected <- samplesheet$cell.type %in% cell.types
    meffil.add.cell.type.reference(
        "gervin and lyle cord blood",
        ds$M[,selected], ds$U[,selected],
        cell.types=samplesheet$cell.type[selected],
        chip="450k",
        featureset="common",
        description="Cord blood reference of Gervin et al. Epigenetics 2016",
        verbose=verbose)
}

