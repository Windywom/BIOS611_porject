BIOS611 Project
========================================================

DATA Set: UNC/UMN Baby Connectome Project

Why: The infant brain experiences rapid growth in the first few years of life. Recently, Integrated Information Decomposition was developed to quantify human brain information-processing. Precisely delineating the normative functional development of this critical period from the information-processing view may reveal distinct information-resolved connectivity patterns. 
Objective:  Developmental patterns of nodal information attributes are spatially heterogeneous and regionally specific, which could reflect unique functional roles of different regions. Certain brain regions’ developmental attributes are associated with early cognitive ability.

Thanks for review my project!


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
docker build . -t sci611

```

This will create a docker container. Users using a unix-flavor should
be able to start an RStudio server by running:

```
docker run --rm -p 8787:8787 -v $(pwd):/home/rstudio/work -e PASSWORD=pwd -it sci611
```

You then visit http://localhost:8787 via a browser on your machine to
access the machine and development environment. 

Project Organization
====================

The best way to understand what this project does is to examine the
Makefile.

A Makefile is a textual description of the relationships between
_artifacts_ (like data, figures, source files, etc). In particular, it
documents for each artifact of interest in the project:

1. what is needed to construct that artifact
2. how to construct it
