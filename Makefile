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
figures/importance_BIS.pdf result_xgboost/xgb_importance_BIS.csv: \
 .created-dirs iterative_xgb_dti_BIS_assign.R source_data_DTI/xingweiliaobiao.xlsx \
 source_data_DTI/DTI_FA.xlsx
	Rscript iterative_xgb_dti_BIS_assign.R

# xgboost predict TAS using DTI results.
figures/importance_TAS.pdf result_xgboost/xgb_importance_TAS.csv: \
 .created-dirs iterative_xgb_dti_TAS_assign.R source_data_DTI/xingweiliaobiao.xlsx \
 source_data_DTI/DTI_FA.xlsx
	Rscript iterative_xgb_dti_TAS_assign.R
	
# xgboost predict HB using DTI results.
figures/importance_HB.pdf result_xgboost/xgb_importance_HB.csv: \
 .created-dirs iterative_xgb_dti_HB_assign.R source_data_DTI/xingweiliaobiao.xlsx \
 source_data_DTI/DTI_FA.xlsx
	Rscript iterative_xgb_dti_HB_assign.R
	
# Compare xgboost predict perfromance with random forest and linear regression in Python.
result_xgboost/important_feature_py.csv result_xgboost/rsqure.csv result_xgboost/neg_mean_squared_error.csv: \
 .created-dirs xgboost_DTI.py source_data_DTI/xingweiliaobiao.xlsx \
 source_data_DTI/DTI_FA.xlsx
	python3 xgboost_DTI.py

# Build the final report for the project.
writeup.pdf: figures/importance_BIS.pdf figures/importance_TAS.pdf figures/importance_HB.pdf
	pdflatex writeup.tex

report.pdf: figures/importance_BIS.pdf figures/importance_TAS.pdf figures/importance_HB.pdf
	R -e "rmarkdown::render(\"writeup.Rmd\", output_format=\"pdf_document\")"
