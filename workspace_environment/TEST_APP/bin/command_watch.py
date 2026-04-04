import os
import time
import subprocess


workspace_dir = os.environ.get("WORKSPACE_HOME")
CMD_FILE =  os.path.join(workspace_dir, "temp", "command.txt")
OUT_FILE =  os.path.join(workspace_dir, "temp", "result.txt")

print("명령 대기중...")

while True:
    if os.path.exists(CMD_FILE):
        with open(CMD_FILE, "r") as f:
            cmd = f.read().strip()
        if not cmd:
            time.sleep(1)
            continue

        print(f"명령 실행: {cmd}")
        try:
            # 명령 실행
            proc = subprocess.run(
                cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, executable="/bin/bash"
            )
            output = proc.stdout.decode(errors="replace")
            # 결과 파일에 출력 & 리턴코드 저장
            with open(OUT_FILE, "w") as out_f:
                out_f.write(f"=== 명령어 ===\n{cmd}\n\n")
                out_f.write(f"=== 표준 출력 ===\n{output}\n")
                out_f.write(f"=== 종료 코드 ===\n{proc.returncode}\n")
        except Exception as e:
            with open(OUT_FILE, "w") as out_f:
                out_f.write(f"에러: {str(e)}\n")

        # 실행 후 명령 파일 삭제
        os.remove(CMD_FILE)

    time.sleep(1)
