# Worldwide (HGDP) — Ancestry Estimation panel

Cloudgene app (`category: AncestryPanel`) that populates the **Ancestry Estimation**
dropdown on the PGS submission form. Without an app in this category the dropdown
only offers *Disabled*, which is why the upstream local-PGS-server tutorial's
install has no ancestry option.

The `imputationserver2` ancestry sub-workflow (`workflows/ancestry_estimation.nf`)
picks its reference files out of the `references` glob **strictly by extension**,
so exactly one file per extension may match `HGDP_938.*`.

| Extension | File | Content | Tracked in git? |
|---|---|---|---|
| `.geno` | `HGDP_938.geno` | LASER genotype matrix, 938 × 632,958 (1.2 GB) | no — download |
| `.site` | `HGDP_938.site` | `CHR POS ID REF ALT`, header row, hg19, no `chr` prefix | no — download |
| `.coord` | `HGDP_938.RefPC.coord` | Reference PCA coordinates (`popID indivID PC1…PC100`) | no — download |
| `.range` | `HGDP_938.range` | `CHR START END` per site, no header | no — derived |
| `.samples` | `HGDP_938.samples` | `superpopID indivID`, header row | **yes** |

`LASER-HGDP-ReadMe.txt` is the upstream ReadMe, kept for the citation text.

## Rebuild recipe

```bash
cd apps/ancestry-hgdp-worldwide/1.0.0

# 1. LASER HGDP reference panel (hg19, 938 samples, 632,958 SNPs; ~161 MB)
curl -O https://csg.sph.umich.edu/chaolong/LASER/HGDP-938-632958.tar.gz
tar xzf HGDP-938-632958.tar.gz
mv HGDP/HGDP_938.geno HGDP/HGDP_938.site HGDP/HGDP_938.RefPC.coord .
cp HGDP/ReadMe.txt LASER-HGDP-ReadMe.txt
rm -rf HGDP HGDP-938-632958.tar.gz

# 2. Derive the .range file from the .site file (skip header; CHR START END)
awk 'NR>1 {print $1"\t"$2"\t"$2}' HGDP_938.site > HGDP_938.range
```

Do **not** leave `HGDP_938.RefPC.var` or `HGDP_938.bed` in this directory — a stray
second file matching `HGDP_938.*` with a reference extension breaks file selection.

`HGDP_938.samples` is the production sample → super-population map, copied verbatim
from `apps/imputationserver2-pgs/2.0.12/tests/data/input/ancestry/HGDP_238_chr22.samples`.
Despite that file's name it holds all 938 HGDP individuals, and its IDs match
`HGDP_938.RefPC.coord` exactly. Label counts: AFR 102, AMR 63, EAS 229, EUR 156,
GME 160, OTH 28, SAS 200.

## Registration

The app is registered in `config/settings.yaml` as
`apps/ancestry-hgdp-worldwide/1.0.0/cloudgene.yaml`. Re-register after a rebuild with:

```bash
./cloudgene install apps/ancestry-hgdp-worldwide/1.0.0
```

Note that `cloudgene install <folder>` registers the folder **in place** rather than
copying it under `apps/`, so install it from its final location.

## Constraints

- **hg19 input only.** `imputationserver-utils` ≤ v1.5.3 hardcodes hg19 in
  `prepare-trace` and its liftover branch is unfinished, so a job that enables
  ancestry with Array Build = GRCh38/hg38 fails with a missing-chain-file error.
  Imputation itself still handles hg38; only ancestry is restricted.
- Uploaded genotypes need ≥100 variants matching the reference on `chrom:pos` **and**
  exact `REF/ALT`. Allele-switched sites are dropped, not flipped.
- Ancestry runs on the raw uploaded VCFs (pre-QC, pre-imputation), in parallel with
  imputation, so the reference-panel choice does not affect ancestry results.

## Resources

Process memory is tuned in `config/imputationserver2-pgs/2.0.12/nextflow.config`;
the upstream defaults in the app's `conf/base.config` were sized for the chr22 test
panel and are too small for this one.

## Citation

- Li, J.Z. et al. (2008) Worldwide human relationships inferred from genome-wide
  patterns of variation. *Science* 319:1100. — original HGDP data
- Wang, C. et al. (2014) Ancestry estimation and control of population stratification
  for sequence-based association studies. *Nature Genetics* 46:409. — LASER processing
