Demographic Effects on Pain Reprocessing Therapy Success
========================================================

![d3 visualization](./static-figures/d3-vis.png)

This repository contains an analysis of demographic data associated
with the paper ["Effect of Pain Reprocessing Therapy vs Placebo and
Usual Care for Patients With Chronic Back Pain: A Randomized Clinical
Trial" (Ashar et al, JAMA Psychiatry 2021).](https://jamanetwork.com/journals/jamapsychiatry/fullarticle/2784694 "The Paper")

This repository holds a copy of (some of) the data from that study for
convenience but it is also available
[here](https://figshare.com/s/1840dc4c0e236a7072ca).

Using This Repository
=====================

This repository is best used via Docker although you may be able to
consult the Dockerfile to understand what requirements are appropriate
to run the code.

Docker is a tool from software engineering (really, deployment) which
is nevertheless of great use to the data scientist. Docker builds an
_environment_ (think of it as a light weight virtual computer) which
contains all the software needed for the project. This allows any user
with Docker (or a compatible system) to run the code without bothering
with the often complex task of installing all the required libraries.

One Docker container is provided for both "production" and
"development." To build it you will need to create a file called
`.password` which contains the password you'd like to use for the
rstudio user in the Docker container. Then you run:

```
docker build . --build-arg linux_user_pwd="$(cat .password)" -t ashar
```

This will create a docker container. Users using a unix-flavor should
be able to start an RStudio server by running:

```
docker run -v $(pwd):/home/rstudio/ashar-ws\
           -p 8787:8787\
           -p 8888:8888\
           -e PASSWORD="$(cat .password)"\
           -it ashar
```

You then visit http://localhost:8787 via a browser on your machine to
access the machine and development environment. For the curious, we
also expose port 8888 so that we can launch other servers from in the
container.

Project Organization
====================

The best way to understand what this project does is to examine the
Makefile.

A Makefile is a textual description of the relationships between
_artifacts_ (like data, figures, source files, etc). In particular, it
documents for each artifact of interest in the project:

1. what is needed to construct that artifact
2. how to construct it

But a Makefile is more than documentation. Using the _tool_ make
(included in the Docker container), the Makefile allows for the
automatic reproduction of an artifact (and all the artifacts which it
depends on) by simply issueing the command to make it.

Consider this snippet from the Makefile included in this project:

```
# Since our clustering is based on a variational auto-encoder it is
# difficult to understand what the clusters represent.  Here we use
# gradient boosting to train a tree model on the raw data to predict
# each cluster. From this model we can extract the important variables
# for each cluster and report their medians. We simply save the labels
# here for future use.
derived_data/cluster_labels.csv: .created-dirs explain_encoding.R derived_data/demographic_ae_sdf.csv
	Rscript explain_encoding.R
```

The lines with `#` are comments which just describe the target. Here
we describe an artifact (`derived_data/cluster_labels.csv`), its
dependencies (`.created-dirs`, `explain_encoding.R`,
`derived_data/demographic_ae_sdf.csv`) and how to build it `Rscript
explain_encoding.R`. If we invoke Make like so:

```
make derived_data/cluster_labels.csv
```

Make will construct this artifact for us. If the dependency
`derived_data/demographic_ae_sdf.csv` doesn't exist for some reason it
will _also_ construct that artifact on the way. This greatly
simplifies the reproducibility of builds and also documents
dependencies.

What to Look At
===============

There are two products of this analysis.

1. A visualization of the relationship between demographics and
   treatment effect for the Ashar 2021 Data.
2. A report on how the details of the results.

In the first case you can run the phony target:

```
make visualization
```

This will start a server on the port 8888. If you started your Docker
container per the instructions above you should be able to access the
visualization in your browser by visiting `http://localhost:8888`.

In the second case you simply invoke:

```
make writeup.pdf
```

And this will build the report and any missing dependencies required
on the way.

Results
=======

This analysis reveals significant differences in treatment response
related to demographics. Build the report to find out the details.

