# scores/

Harmonized individual score weight files from the PGS Catalog v20221123 release (hg19). Each file is a bgzipped tab-separated text file for one PGS score, with an accompanying `.log` file from the harmonization pipeline.

## Expected file pattern

```
PGS<id>.txt.gz      # variant weights, harmonized to hg19
PGS<id>.log         # harmonization log
```

## Source

PGS Catalog (https://www.pgscatalog.org), release 2022-11-23.
Downloaded and harmonized using the PGS Catalog harmonization pipeline.
