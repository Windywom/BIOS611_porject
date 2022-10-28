

[NUMERIC,TXT,RAW]=xlsread('D:\bios-611-project\source_data_DTI\WMlabelResults_FA1.xlsx');
NUMERIC(find(isnan(NUMERIC)==1)) = 0;
%select the apd subjects
apd_dti=NUMERIC(1:23,:);
apd_dti([4,18 19],:)=[];


[NUMERIC,TXT,RAW]=xlsread('D:\bios-611-project\source_data_DTI\WMlabelResults_FA.xlsx');
NUMERIC(find(isnan(NUMERIC)==1)) = 0;
%select the control subjects
con_dti=NUMERIC(1:30,:);
con_dti([4,5,23 26:29],:)=[];

sub_dti=[apd_dti;con_dti];