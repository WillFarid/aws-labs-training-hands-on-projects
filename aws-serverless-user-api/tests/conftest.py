import os

# boto3 needs a region at import time; tests never contact AWS.
os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")
