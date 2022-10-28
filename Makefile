.PHONY: clean
.PHONY: d3-vis
.PHONY: visualization

clean:
	rm -rf models
	rm -rf figures
	rm -rf result_xgboost
	rm -rf .created-dirs
	rm -f writeup.pdf

.created-dirs:
	mkdir -p models
	mkdir -p figures
	mkdir -p result_xgboost
	touch .created-dirs

# xgboost predict BIS using DTI results.
figures/importance_BIS.pdf results/xgb_importance_BIS.csv: \
 .created-dirs iterative_xgb_dti_BIS_assign.R source_data_DTI/xingweiliaobiao.xlsx \
 source_data_DTI/DTI_FA.xlsx
	Rscript iterative_xgb_dti_BIS_assign.R

# xgboost predict TAS using DTI results.
figures/importance_TAS.pdf results/xgb_importance_TAS.csv: \
 .created-dirs iterative_xgb_dti_TAS_assign.R source_data_DTI/xingweiliaobiao.xlsx \
 source_data_DTI/DTI_FA.xlsx
	Rscript iterative_xgb_dti_TAS_assign.R

# Attempt a clustering based on clinical outcomes but ignoring
# time. See above. Not all that useful. There aren't distinct clusters
# except in the sense that people report different levels of pain on a
# quantized scale. Not very useful.
derived_data/clinical-outcomes-with-clustering.csv\
 figures/clinical-outcomes-clustering.png:\
  cluster-clinical-outcomes.py\
  .created-dirs\
  derived_data/clinical-outcomes-with-ae.csv
	python3 cluster-clinical-outcomes.py

figures/bpi_intensity_by_group.png: source_data/clinical_outcomes.csv bpi_intensity_by_group.R derived_data/clinical_outcomes-d3.csv
	Rscript bpi_intensity_by_group.R

# Plots of various non-projected properties of clinical outcomes per
# cluster. Not very interesting because the clusters are not very
# interesting and the AE projection is just (roughly) back pain
# intensity.
# Note this uses a sentinal value because we produce many plots.
sentinels/cluster-plots.txt: .created-dirs\
 derived_data/clinical-outcomes-with-clustering.csv\
 cluster-plots.R
	Rscript cluster-plots.R

# Similar to above.
sentinels/boxplots.txt: .created-dirs\
 source_data/clinical_outcomes.csv\
 box-scatters.R
	Rscript box-scatters.R


# Augment the clinical outcomes data (with its AE projection) with
# time points so that we can view them in a d3 visualization. Not
# useful.
derived_data/clinical_outcomes-d3.csv: .created-dirs\
 derived_data/clinical-outcomes-with-clustering.csv\
 augment-with-experimental-time.R\
 derived_data/demographic_ae.csv
	Rscript augment-with-experimental-time.R

# Train a (variational) auto-encoder for demographic data. This allows
# us to see some obvious demographic groups and makes (tuning)
# clustering easier. See "explain_encoding.R" for code which helps us
# understand what these clusters represent.  Produce two targets here:
# One with the normalized data (sdf) and one with the original data.
models/demographics-ae models/demographics-enc derived_data/normalized_demographics.csv: demographics-ae.py\
 source_data/demographics.csv
	python3 demographics-ae.py

derived_data/demographic_ae_sdf.csv derived_data/demographic_ae.csv figures/demo-projection.png figures/demo-projection.svg: demographic-clustering.py\
 models/demographics-ae\
 models/demographics-enc\
 derived_data/normalized_demographics.csv
	python3 demographic-clustering.py

# Since our clustering is based on a variational auto-encoder it is
# difficult to understand what the clusters represent.  Here we use
# gradient boosting to train a tree model on the raw data to predict
# each cluster. From this model we can extract the important variables
# for each cluster and report their medians. We simply save the labels
# here for future use.
derived_data/cluster_labels.csv: .created-dirs explain_encoding.R derived_data/demographic_ae_sdf.csv
	Rscript explain_encoding.R

# Produce a figure which shows the clinical outcomes for our
# demographic clusters. Use the labels we calculated above to make the
# results comprehensible.
figures/outcomes_by_demographic_clustering.png figures/outcomes_by_demographic_clustering.svg: .created-dirs\
 demo-outcomes.R\
 derived_data/clinical-outcomes-with-clustering.csv\
 derived_data/cluster_labels.csv\
 derived_data/demographic_ae.csv
	Rscript demo-outcomes.R

# dummy target to show a d3 visualization.
d3-vis: derived_data/clinical_outcomes-d3.csv
	python3 -m http.server 8888


derived_data/meta-data.csv: source_data/clinical_outcomes.csv source_data/demographics.csv gen-meta-data.R
	Rscript gen-meta-data.R

derived_data/patient-count.fragment.Rmd: source_data/demographics.csv count-subject-types.R
	Rscript count-subject-types.R

# Start a server for the d3 visualization of the results of this
# project.
visualization: derived_data/clinical_outcomes-d3.csv 
	lighttpd -D -f lighttpd.conf

# Build the final report for the project.
writeup.pdf: figures/bpi_intensity_by_group.png figures/demo-projection.png figures/outcomes_by_demographic_clustering.png
	pdflatex writeup.tex

report.pdf: figures/bpi_intensity_by_group.png figures/demo-projection.png figures/outcomes_by_demographic_clustering.png derived_data/patient-count.fragment.Rmd
	R -e "rmarkdown::render(\"writeup.Rmd\", output_format=\"pdf_document\")"
