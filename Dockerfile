FROM rocker/verse
WORKDIR /
RUN R -e "install.packages(\"readxl\")";
RUN R -e "install.packages(\"xgboost\")";
RUN R -e "install.packages(\"ParBayesianOptimization\")";
RUN R -e "install.packages(\"minqa\")";
RUN apt update && apt-get install -y nodejs
RUN apt update && apt-get install -y openssh-server python3-pip
RUN pip3 install --pre --user hy
RUN pip3 install beautifulsoup4 theano tensorflow keras sklearn pandas numpy pandasql
RUN pip3 install xgboost scipy scikit-learn
RUN ssh-keygen -A
RUN mkdir -p /run/sshd
RUN sudo usermod -aG sudo rstudio

WORKDIR /
RUN R -e "install.packages(c(\"shiny\",\"deSolve\",\"signal\"))" 
RUN R -e "install.packages(\"Rcpp\")";
RUN R -e "install.packages(\"reticulate\")";
RUN R -e "install.packages(\"ppclust\")";
RUN R -e "install.packages(\"gbm\")";
RUN R -e "install.packages(\"caret\")";
RUN R -e "install.packages(c(\"shiny\",\"plotly\",\"lmerTest\",\"MuMIn\"))";
RUN pip3 install jupyter jupyterlab
RUN pip3 install matplotlib plotly bokeh plotnine dplython
RUN apt update && apt install -y software-properties-common
RUN add-apt-repository ppa:kelleyk/emacs
RUN DEBIAN_FRONTEND=noninteractive apt update && DEBIAN_FRONTEND=noninteractive apt install -y emacs28
