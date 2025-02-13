# meffil

> Min JL, Hemani G, Davey Smith G, Relton C, Suderman M.
> [Meffil: efficient normalization and analysis of very large DNA methylation datasets](https://www.ncbi.nlm.nih.gov/pubmed/29931280).
> Bioinformatics. 2018 Jun 21.

Efficient algorithms for analyzing DNA methylation data
generated using Infinium HumanMethylation450 or MethylationEPIC **(v1 and v2)** BeadChips:

* Functional normalization for large datasets using parallelization.
* Normalization of datasets with mixed Infinium HumanMethylation450 and MethylationEPIC **(v1 and v2)** BeadChips.
* Inclusion of user-defined fixed and random effects in functional normalization procedure.
* Cell count estimation using predefined and user-defined reference datasets.
* Use of predefined and user-defined microarray probe annotations.
* Epigenome-wide association studies (using data from any normalization pipeline).
* Copy number estimation.
* Report generation summarizing all steps.
* The online wiki can be found [here](https://github.com/perishky/meffil/wiki)
* **Normalization to** and **epigenome-wide-studies and report generation for** methylation matrices stored in [Genomic Data Structure files](https://bioconductor.org/packages/release/bioc/html/gdsfmt.html). *The methylation matrix never needs to be loaded into memory*.

Examples using many of these features can be found in the
[tests/](tests) directory.

## Installation

Only a few steps are needed to install `meffil` in R. First, start R and then type the following commands:

    source("http://bioconductor.org/biocLite.R")
    install.packages("devtools") # if the devtools package is not installed
    library(devtools)
    install_github("perishky/meffil")

## One-step normalization

	library(meffil)
	options(mc.cores=6)

	# Generate samplesheet
	samplesheet <- meffil.create.samplesheet(path_to_idat_files)

	# Or read in samplesheet
	samplesheet <- meffil.read.samplesheet(path_to_idat_files)

    beta <- meffil.normalize.dataset(samplesheet, qc.file="qc/report.html", author="Analyst", study="Illumina450", number.pcs=10)

## Step-by-step normalization

	# Load meffil and set how many cores to use for parallelization
	library(meffil)
	options(mc.cores=6)

	# Generate samplesheet
	samplesheet <- meffil.create.samplesheet(path_to_idat_files)

	# Or read in samplesheet
	samplesheet <- meffil.read.samplesheet(path_to_idat_files)

	# Background and dye bias correction, sexprediction, cell counts estimates
	qc.objects <- meffil.qc(samplesheet, cell.type.reference="blood gse35069", verbose=TRUE)

    # Obtain genotypes for comparison with those measured on the microarray
	genotypes <- meffil.extract.genotypes(plink.files)

	# Generate QC report
	qc.summary <- meffil.qc.summary(qc.objects, genotypes=genotypes)
	meffil.qc.report(qc.summary, output.file="qc/report.html")

	# Remove outlier samples if necessary
	qc.objects <- meffil.remove.samples(qc.objects, qc.summary$bad.samples$sample.name)

    # Plot residuals remaining after fitting control matrix to decide on the number PCs
	# to include in the normalization below.
	print(meffil.plot.pc.fit(qc.objects)$plot)

	# Perform quantile normalization
	norm.objects <- meffil.normalize.quantiles(qc.objects, number.pcs=10)

	# Generate normalized probe values
	norm.beta <- meffil.normalize.samples(norm.objects, cpglist.remove=qc.summary$bad.cpgs$name)

	# Generate normalization report
	pcs <- meffil.methylation.pcs(norm.beta)
	norm.summary <- meffil.normalization.summary(norm.objects, pcs=pcs)
	meffil.normalization.report(norm.summary, output.file="normalization/report.html")

## More info about normalization

Loading `meffil`

	library(meffil)
	options(mc.cores=16)

We generate a samplesheet automatically from the `.idat` files:

	samplesheet <- meffil.create.samplesheet(path)

The function creates the following necessary columns:

- Sample_Name
- Sex (possible values "M"/"F"/NA)
- Basename

And it also tries to parse the basenames to guess if the Sentrix plate
and positions are present. At this point it is worthwhile to manually
modify the `samplesheet` data.frame to replace the actual sample IDs
in the `Sample_Name` column if necessary, and to add the sex values to
the `Sex` column. Don't change these column names though.

Perform the background correction, dye bias correction, sex prediction and cell count estimation:

	qc.objects <- meffil.qc(samplesheet, cell.type.reference="blood gse35069", verbose=TRUE)

A list of available cell type references can be obtained as follows:

	meffil.list.cell.type.references()

New references can be created from a dataset using meffil.create.cell.type.reference().

If the data was generated by multiple array platforms (e.g. 450k, EPIC v1 and and EPIC v2), then `meffil.qc()` should be 'warned' about what combination of platforms to expect by setting the `featureset` parameter
to something like "450k:epic" (i.e. 450k and EPIC v1) or "450k:epic:epic2" (i.e. 450k, EPIC v1, EPIC v2).
*Note that normalizing data from multiple platforms has not be well-studied, so outputs should be interpreted with caution.*

A list of available feature sets can be obtained as follows:

	meffil.list.featuresets()

Obtain the matrix of genotypes for comparison with those measured on the microarray.
If such a matrix is available (rows = SNPs, columns = samples), then the following steps
can be omitted.  Otherwise, it is possible to obtain the matrix from a PLINK
dataset as follows:

	## save the SNP names in R
	featureset <- qc.objects[[1]]$featureset
	writeLines(meffil.snp.names(featureset), con="snp-names.txt")
	
	## run plink at the command line
    plink --bfile dataset --extract snp-names.txt --recodeA --out genotypes.raw --noweb

	## load the genotype data in R
    filenames <- "genotypes.raw"
    genotypes <- meffil.extract.genotypes(filenames)

We can now summarise the QC analysis of the raw data

	qc.summary <- meffil.qc.summary(qc.objects, genotypes=genotypes)

and generate a report:
	
	meffil.qc.report(qc.summary, output.file="qc/report.html")

This creates the file "qc/report.html" in the current work directory.
Should open up in your web browser.

You can remove bad samples prior to performing quantile normalization:

	qc.objects <- meffil.remove.samples(qc.objects, qc.summary$bad.samples$sample.name)

Next we determine the number of principal components of the control matrix
to include in the quantile normalization.
The following function plots the quantile residuals remaining
after fitting different numbers of control matrix principal components.

    print(meffil.plot.pc.fit(qc.objects)$plot)

And now remove control probe variance from the sample quantiles:

	norm.objects <- meffil.normalize.quantiles(qc.objects, number.pcs=10)

Additional fixed and random effects can be included in the normalization
by providing their corresponding column names in the samplesheet.
For example, slide effects can be included as follows:

    norm.objects <- meffil.normalize.quantiles(qc.objects, random.effects="Slide", number.pcs=10)

Note however that including random effects will greatly increase running time.

Finally, the `beta` values can be generated, whilst removing CpGs
that were found to be dodgy in the QC analysis:

	norm.beta <- meffil.normalize.samples(norm.objects, cpglist.remove=qc.summary$bad.cpgs$name)

A summary report of the normalization performance can also be generated:

    pcs <- meffil.methylation.pcs(norm.beta)
	norm.summary <- meffil.normalization.summary(norm.objects, pcs=pcs)
	meffil.normalization.report(norm.summary, output.file="normalization/report.html")

## Epigenome-wide association study (EWAS)

Prepare a variable of interest and a set of covariates.

    variable <- ... ## variable of interest, one value per sample
    covariates <- ... ## data.frame of covariates to include (rows = samples, columns = covariates)

Add cell count estimates to the set  of covariates.

    counts <- t(meffil.cell.count.estimates(norm.objects))
	covariates <- cbind(covariates, counts)

Run the EWAS.

    ewas.ret <- meffil.ewas(norm.beta, variable=variable, covariates=covariates)

Generate a report for the EWAS, including a table describing
all variables, a table describing the relationships between the variable of interest
and all covariates, QQ plots, Manhattan plots, a spreadsheet listing all significantly associated CpG sites,
plots of the most strongly associated sites,
and plots of selected candidate CpG sites.

    ewas.parameters <- meffil.ewas.parameters(sig.threshold=1e-20, max.plots=5)
    candidate.sites <- c("cg04946709","cg06710937","cg12177922","cg15817705","cg20299935","cg21784396")
    ewas.summary <- meffil.ewas.summary(ewas.ret,
                                        norm.beta,
                                        selected.cpg.sites=candidate.sites,
                                        parameters=ewas.parameter)								
    meffil.ewas.report(ewas.summary, output.file="ewas/report.html")


## Using meffil in a container with Singularity
```bash
singularity pull docker://quay.io/sarahbeecroft9/meffil:latest
singularity exec meffil_latest.sif R
```


