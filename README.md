# loki-evaluation
Evaluate Loki for bulk ingest and query

Follow these steps to run the evaluation:

1. Set the working directory
  ```
  cd loki
  ```
  
2. Login to the cluster
  ```
  ./login.sh
  ```
  
3. Deploy Loki on the cluster
  ```
  ./deploy_loki.sh
  ```
  
4. Run the write path scenario
  ```
  ./multi_upload_file_to_loki_with_promtail_using_container.sh
  ```
  
5. Redeploy Loki
  ```
  ./deploy_loki.sh
  ```
  
6. Run the read path scenario
  ```
  ./multi_download_from_loki_with_logcli_using_container.sh
  ```
