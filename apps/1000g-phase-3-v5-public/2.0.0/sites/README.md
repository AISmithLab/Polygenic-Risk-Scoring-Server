# sites/

Per-chromosome site-frequency files used during quality control to filter and validate input variants against the reference panel. Each file is bgzipped and tabix-indexed.

## Expected files

One sites file + tabix index per chromosome (1–22, X):

```
ALL_1000G_phase3_integrated_v5_chr1.sites.gz
ALL_1000G_phase3_integrated_v5_chr1.sites.gz.tbi
...
ALL_1000G_phase3_integrated_v5_chr22.sites.gz
ALL_1000G_phase3_integrated_v5_chr22.sites.gz.tbi
ALL_1000G_phase3_integrated_v5_chrX.sites.gz
ALL_1000G_phase3_integrated_v5_chrX.sites.gz.tbi
```

## Source

Michigan Imputation Server reference panel distribution:
https://imputationserver.sph.umich.edu/start.html#!pages/refpanels
