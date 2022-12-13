## Description

The Spotted Lanternfly (*Lycorma delicatula*) is an invasive pest species in the North Eastern USA, first discovered in Berks County, PA, in 2014. Since its first discovery, several agencies (with the Pennsylvania Dept. of Agriculture, and the US Dept. of Agriculture in a leading role) have taken up the task to monitor and control SLF populations.

The package `lydemap` combines survey datasets produced by different agencies in the United States (at the local, state, and federal level) into a single aggregated and anonymized dataset. This includes information on the approximate location where each survey was conducted, the provenance of the data point, as well as biologically relevant results of the surveys (presence/absence of the Spotted Lanternfly, presence of an established population, and estimated population density of this pest).


### How to use this project

There are three ways to obtain the package and the data associated with it.

#### 1. Downloading the data only

The data itself can be obtained separately by downloading the compressed folder `/download_data` directly form [this github page](https://github.com/ieco-lab/lydemap). The folder contains a compressed folder with two version of the data in `.csv` format, alongside a Metadata file to understand and use the data.

#### 2. Installing the package in R

The package `lydemap` can be installed by the user in an instance of R or RStudio by typing.

```
require(devtools)
devtools::install_github("ieco-lab/lydemap")
```

#### 3. Cloning the package locally

If the user wishes to access the full content of the package, `lydemap` needs to be cloned locally.
To do so, open your Terminal or git shell, and `cd` to the appropriate folder where you want the project to be stored. Then, type: 

```
git clone https://github.com/ieco-lab/lydemap.git
```



