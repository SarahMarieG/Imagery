#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/sgardy/Documents/SarahData/Imagery/Data/rawMRI"
TIMING_ROOT="$ROOT/timing"
TPL="MNI152_2009_template_SSW.nii.gz"
CONDS=(contam ero neu oth PerNeu PerPl PerUn rew surv)
BLUR=4.0

join_by_space() { local IFS=" "; echo "$*"; }

for subjdir in "$ROOT"/par_*; do
  [ -d "$subjdir" ] || continue
  subj=$(basename "$subjdir")
  echo "====================================================="
  echo "Subject: $subj"

  # ---- sswarper2 outputs (required) ----
  sswdir="$subjdir/sswarper"
  anatSS="$sswdir/anatSS.${subj}.nii"
  anatQQ="$sswdir/anatQQ.${subj}.nii"
  aff12="$sswdir/anatQQ.${subj}.aff12.1D"
  warp="$sswdir/anatQQ.${subj}_WARP.nii"
  if [[ ! -s "$anatSS" || ! -s "$anatQQ" || ! -s "$aff12" || ! -s "$warp" ]]; then
    echo "  !! missing sswarper2 outputs in $sswdir (skip)"; echo; continue
  fi

  # ---- anatomy follower (with skull) ----
  anatdir="$subjdir/anat"
  t1raw=$(ls "$anatdir"/*.nii 2>/dev/null | head -n 1 || true)
  if [[ -z "${t1raw}" ]]; then
    echo "  !! no T1 .nii in $anatdir (skip)"; echo; continue
  fi

  # ---- functional EPIs (use all; no concatenation) ----
  funcdir="$subjdir/func"
  func_all=($(ls "$funcdir"/*.nii 2>/dev/null | sort -V))
  if (( ${#func_all[@]} == 0 )); then
    echo "  !! no 4D EPI in $funcdir (skip)"; echo; continue
  fi

  # keep only true 4D (>=2 timepoints)
  dsets_arr=()
  for f in "${func_all[@]}"; do
    nt=$(3dinfo -nt "$f" 2>/dev/null || echo 0)
    (( nt >= 2 )) && dsets_arr+=("$f")
  done
  if (( ${#dsets_arr[@]} == 0 )); then
    echo "  !! found EPIs but none with nt>=2 (skip)"; echo; continue
  fi
  dsets=$(join_by_space "${dsets_arr[@]}")
  echo "  Using EPIs as one logical run:"
  printf '    %s\n' "${dsets_arr[@]}"

  tdir="$TIMING_ROOT/$subj"
  if [[ ! -d "$tdir" ]]; then echo "  !! no timing dir $tdir (skip)"; echo; continue; fi

  stim_files=()
  for c in "${CONDS[@]}"; do
    tf=$(ls "$tdir"/O[12].${c}.txt 2>/dev/null | head -n1)
    [[ -n "$tf" && -s "$tf" ]] || { echo "  !! missing timing for $c in $tdir"; continue 2; }
    stim_files+=("$tf")
  done

  # ---- output dir ----
  outdir="$subjdir/PROC_${subj}_e6b"
  if [[ -d "$outdir" ]]; then
    outdir="${outdir}_$(date +%Y%m%d-%H%M%S)"
  fi
  echo "  Output dir (to be created): $outdir"

  afni_proc.py \
    -subj_id "$subj" \
    -copy_anat "$anatSS" \
    -anat_has_skull no \
    -anat_follower anat_w_skull anat "$t1raw" \
    -dsets $dsets \
    -blocks tshift align tlrc volreg mask blur scale regress \
    -tcat_remove_first_trs 0 \
    -radial_correlate_blocks tcat volreg \
    -align_unifize_epi local \
    -align_opts_aea -cost lpc+ZZ -giant_move -check_flip \
    -tlrc_base "$TPL" \
    -tlrc_NL_warp \
    -tlrc_NL_warped_dsets "$anatQQ" "$aff12" "$warp" \
    -volreg_align_to MIN_OUTLIER \
    -volreg_align_e2a \
    -volreg_tlrc_warp \
    -volreg_compute_tsnr yes \
    -mask_epi_anat yes \
    -blur_size "$BLUR" \
    -regress_stim_times $(join_by_space "${stim_files[@]}") \
  -regress_stim_labels $(join_by_space "${CONDS[@]}") \
  -regress_basis 'CSPLINzero(0,12,8)' \
  -regress_censor_motion 0.3 \
  -regress_censor_outliers 0.1 \
  -regress_reml_exec \
  -regress_compute_fitts \
  -regress_make_ideal_sum sum_ideal.1D \
  -regress_est_blur_epits \
  -regress_est_blur_errts \
  -html_review_style pythonic \
  -out_dir "$outdir" \
  -regress_opts_3dD -global_times \
  -regress_opts_3dD -concat "1D: 0 1017" \
  -regress_opts_3dD \
      -gltsym 'SYM: +contam +PerUn -neu -PerNeu' -glt_label 1 aversive_gt_neutral \
      -gltsym 'SYM: +ero +rew +PerPl -neu -PerNeu' -glt_label 2 appetitive_gt_neutral \
      -gltsym 'SYM: +contam +PerUn -ero -rew -PerPl' -glt_label 3 aversive_gt_appetitive \
      -gltsym 'SYM: +contam +PerUn +ero +rew +PerPl +oth +surv -neu -PerNeu' -glt_label 4 nonneutral_gt_neutral \
      -gltsym 'SYM: +PerUn' -glt_label 5 PerUn_vs_base \
      -gltsym 'SYM: +PerPl' -glt_label 6 PerPl_vs_base \
      -gltsym 'SYM: +PerNeu' -glt_label 7 PerNeu_vs_base \
  -execute

  echo
done

echo "All subjects submitted."

