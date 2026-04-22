# scores/

Individual polygenic risk score weight files from the Cancer PRSweb v20200608 panel (hg19). Each file is a bgzipped tab-separated text file containing variant weights for one cancer PRS model, with an accompanying `.log` file.

## Expected file pattern

```
PRSWEB_PHECODE<code>_<trait>_<method>_<cohort>_20200608.txt.gz
PRSWEB_PHECODE<code>_<trait>_<method>_<cohort>_20200608.hg19.log
```

## Source

University of Michigan Cancer PRSweb:
https://prsweb.sph.umich.edu/
