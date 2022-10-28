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

