# Kubeflow Pipeline: just a simple test pipeline

This minimal pipeline launches five containers, which are exact replicas of each other.
Each container makes copies of certain input data files within itself, and
persist to the output bucket of the pipeline.

# How to run it

Simply set `export MINIO_SECRET=XXXXXX` in your Jupyter notebook (in Kubeflow)
and then run the script `compute-pi.py`. Check Kubeflow to see the progress!

