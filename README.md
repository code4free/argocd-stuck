# Argo CD issue.
To reproduce the issue you need to run the bug.sh script. It will:
- create a k3s single node cluster (via k3d)
- deploy argo-cd (argocd.yaml)
- deploy the app (app.yaml)
When the app is succesfully Synced and Healthy it will restart the script and do it over again. It will stop once the app is not Synced and Healthy.

# Results
The results from one of the runs are in the [results](results) folder.
