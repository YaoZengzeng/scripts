import argparse
from huggingface_hub import snapshot_download

parser = argparse.ArgumentParser(description='Download model from Hugging Face Hub.')
parser.add_argument('--repo_id', type=str, default='riyazahuja/DeepSeek-R1-Distill-Qwen-1.5B_demo',
                    help='The repository ID of the model to download.')

args = parser.parse_args()

print(f'Repository ID: {args.repo_id}')

sql_lora_path = snapshot_download(args.repo_id)
