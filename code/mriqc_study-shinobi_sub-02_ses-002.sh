#!/bin/bash
#SBATCH --account=rrg-pbellec
#SBATCH --job-name=mriqc_study-shinobi_sub-02_ses-002.job
#SBATCH --output=./code/mriqc_study-shinobi_sub-02_ses-002.out
#SBATCH --error=./code/mriqc_study-shinobi_sub-02_ses-002.err
#SBATCH --time=2:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=4G
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=basile.pinsard@gmail.com



export LOCAL_DATASET=$SLURM_TMPDIR/${SLURM_JOB_NAME//-/}/
flock --verbose /lustre03/project/rrg-pbellec/ria-beluga/alias/cneuromod.shinobi.mriqc/.datalad_lock datalad clone ria+file:///lustre03/project/rrg-pbellec/ria-beluga#~cneuromod.shinobi.mriqc $LOCAL_DATASET
cd $LOCAL_DATASET
git-annex enableremote ria-beluga-storage
datalad get -s ria-beluga-storage -J 4 -n -r -R1 . # get sourcedata/* containers
if [ -d sourcedata/smriprep ] ; then
    datalad get -n sourcedata/smriprep sourcedata/smriprep/sourcedata/freesurfer
fi
git submodule foreach --recursive git annex dead here
git submodule foreach git annex enableremote ria-beluga-storage
git checkout -b $SLURM_JOB_NAME

datalad containers-run -m 'mriqc_sub-02/ses-002' -n containers/bids-mriqc --input sourcedata/shinobi/sub-02/ses-002/fmap/ --input sourcedata/shinobi/sub-02/ses-002/func/ --output . -- -w workdir/ --participant-label 02 --session-id 002 --omp-nthreads 8 --nprocs 8 -m bold --mem_gb 32 --no-sub sourcedata/shinobi ./ participant 
mriqc_exitcode=$?

flock --verbose /lustre03/project/rrg-pbellec/ria-beluga/alias/cneuromod.shinobi.mriqc/.datalad_lock datalad push -d ./ --to origin
if [ -d sourcedata/freesurfer ] ; then
    flock --verbose /lustre03/project/rrg-pbellec/ria-beluga/alias/cneuromod.shinobi.mriqc/.datalad_lock datalad push -J 4 -d sourcedata/freesurfer $LOCAL_DATASET --to origin
fi 
exit $mriqc_exitcode 
