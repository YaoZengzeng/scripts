from huggingface_hub import snapshot_download

repo_id="riyazahuja/DeepSeek-R1-Distill-Qwen-1.5B_demo"

sql_lora_path = snapshot_download(repo_id)
