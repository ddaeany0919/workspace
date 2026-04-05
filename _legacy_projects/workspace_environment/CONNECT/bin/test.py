import subprocess

remote_dir = "/home/luis/CONNECT/lagvm/LINUX/android/external"
exts = [".java"]
ext_filters = " -o ".join([f"-iname '*{ext}'" for ext in exts])
find_expr = f"find {remote_dir} -type f \\( {ext_filters} \\)"

ssh_cmd = ["ssh", "svr", find_expr]  # 'svr' 은 SSH host alias

print(f"🔍 SSH 명령: {' '.join(ssh_cmd)}")
result = subprocess.run(ssh_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

if result.returncode == 0:
    file_list = result.stdout.strip().split("\n")
    print(f"✅ 파일 {len(file_list)}개 발견")
else:
    print(f"❗ 오류 발생: {result.stderr}")