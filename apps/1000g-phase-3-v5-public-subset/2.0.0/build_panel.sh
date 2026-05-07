#!/bin/bash
# Build script: creates a subset 1000G Phase 3 v5 reference panel by removing
# specified samples from the original panel's BCF files and regenerating MSAVs.
#
# Usage: bash build_panel.sh [--threads N] [--start-chr N]
#   --threads N       bcftools/minimac4 threads per job (default: 8)
#   --start-chr N     resume from chromosome N (for restarting after failure)

set -euo pipefail

THREADS=8
START_CHR=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --threads) THREADS="$2"; shift 2 ;;
        --start-chr) START_CHR="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC=/media/volume/PGS-Server-Storage/pgscalcserver/apps/1000g-phase-3-v5-public/2.0.0
DEST="$SCRIPT_DIR"
KEEP="$DEST/keep_samples.txt"
LOG="$DEST/build.log"

MINIMAC_IMAGE=quay.io/genepi/imputationserver2:v2.0.12

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

log "Starting panel build (threads=$THREADS, start_chr=$START_CHR)"
log "Source: $SRC"
log "Dest:   $DEST"
log "Keep:   $(wc -l < "$KEEP") samples"

# ── Symlink sites and map (no per-sample data) ──────────────────────────────
if [[ "$START_CHR" -le 1 ]]; then
    log "Symlinking sites and map directories..."
    for f in "$SRC/sites/"*; do
        target="$DEST/sites/$(basename "$f")"
        [[ -e "$target" ]] || ln -s "$f" "$target"
    done
    for f in "$SRC/map/"*; do
        target="$DEST/map/$(basename "$f")"
        [[ -e "$target" ]] || ln -s "$f" "$target"
    done
    # Copy READMEs
    for dir in bcfs msavs sites map; do
        [[ -f "$SRC/$dir/README.md" ]] && cp -n "$SRC/$dir/README.md" "$DEST/$dir/" || true
    done
fi

# ── Process one chromosome ───────────────────────────────────────────────────
process_chr() {
    local chr="$1"          # e.g. "1", "22", "X.PAR1"
    local bcf_chr="$2"      # e.g. "1", "22", "X.PAR1"
    local msav_label="$3"   # e.g. "1", "22", "X.PAR1"

    local IN_BCF="$SRC/bcfs/ALL.chr${bcf_chr}.phase3_v5.shapeit2_mvncall_integrated.noSingleton.genotypes.recode.bcf"
    local OUT_BCF="$DEST/bcfs/ALL.chr${bcf_chr}.phase3_v5.shapeit2_mvncall_integrated.noSingleton.genotypes.recode.bcf"
    local OUT_MSAV="$DEST/msavs/${msav_label}.1000g.Phase3.v5.With.Parameter.Estimates.msav"

    # ── BCF filtering ──
    if [[ -f "$OUT_BCF" && -f "$OUT_BCF.csi" ]]; then
        log "chr${chr}: BCF already exists, skipping bcftools step"
    else
        log "chr${chr}: filtering BCF..."
        bcftools view \
            -S "$KEEP" \
            --threads "$THREADS" \
            -Ob -o "$OUT_BCF" \
            "$IN_BCF"
        bcftools index -c --threads "$THREADS" "$OUT_BCF"
        log "chr${chr}: BCF done"
    fi

    # ── MSAV creation ──
    if [[ -f "$OUT_MSAV" ]]; then
        log "chr${chr}: MSAV already exists, skipping minimac4 step"
    else
        log "chr${chr}: compressing reference to MSAV..."
        docker run --rm \
            -v "$DEST/bcfs:/bcfs:ro" \
            -v "$DEST/msavs:/msavs" \
            "$MINIMAC_IMAGE" \
            minimac4 \
                --compress-reference "/bcfs/ALL.chr${bcf_chr}.phase3_v5.shapeit2_mvncall_integrated.noSingleton.genotypes.recode.bcf" \
                --threads "$THREADS" \
                -o "/msavs/${msav_label}.1000g.Phase3.v5.With.Parameter.Estimates.msav"
        log "chr${chr}: MSAV done"
    fi
}

# ── Autosomes ────────────────────────────────────────────────────────────────
for chr in $(seq 1 22); do
    [[ "$chr" -lt "$START_CHR" ]] && continue
    process_chr "$chr" "$chr" "$chr"
done

# ── X chromosome (PAR1, PAR2, nonPAR) ───────────────────────────────────────
for region in PAR1 PAR2 nonPAR; do
    process_chr "X.$region" "X.${region}" "X.${region}"
done

log "All chromosomes processed."
log ""
log "Summary:"
log "  BCFs:  $(ls "$DEST/bcfs/"*.bcf 2>/dev/null | wc -l) files"
log "  MSAVs: $(ls "$DEST/msavs/"*.msav 2>/dev/null | wc -l) files"
log "Done."
