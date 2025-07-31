FROM --platform=linux/amd64  us-docker.pkg.dev/deeplearning-platform-release/gcr.io/huggingface-pytorch-training-cu121.2-3.transformers.4-42.ubuntu2204.py310

# Symlink python3 → python for Metaflow
RUN ln -s $(which python3) /usr/bin/python
