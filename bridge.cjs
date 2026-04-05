const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const { spawn } = require('child_process');
const chokidar = require('chokidar');
const path = require('os').homedir();
const fs = require('fs');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });
const port = 3001;

const NEXT_AGENT_CHAIN = {
    "pm-lead": "cto-lead",
    "cto-lead": "code-analyzer",
    "code-analyzer": "developer-expert",
};

function runAutonomousPipeline(initialCommand, socket) {
    console.log(`🤖 [CHAIN START] ${initialCommand}`);
    
    // 윈도우 환경을 위해 쌍따옴표 기반으로 명령 실행
    const child = spawn(initialCommand, { shell: true });

    child.stdout.on('data', (data) => {
        socket.emit('terminal_out', data.toString());
    });

    child.stderr.on('data', (data) => {
        socket.emit('terminal_out', `⚠️ ${data.toString()}`);
    });

    child.on('close', (code) => {
        socket.emit('terminal_close', code);
        
        if (code !== 0) {
            console.error(`❌ [FAILED] Command exited with code ${code}`);
            return;
        }

        // 💡 자율 핸드오프 로직 (홑따옴표 제거 버전)
        for (const [current, next] of Object.entries(NEXT_AGENT_CHAIN)) {
            if (initialCommand.toLowerCase().includes(current)) {
                console.log(`➡️ [AUTO HANDOFF] ${current} -> ${next}`);
                // 윈도우 호환성을 위해 전체를 쌍따옴표로 감싸고 내부도 쌍따옴표 이스케이프
                const nextCmd = `gemini -p \"${next} 에이전트님, 앞서 완료된 작업을 이어받아 다음 단계 분석을 수행하세요.\"`;
                
                setTimeout(() => {
                    runAutonomousPipeline(nextCmd, socket);
                }, 3000);
                break;
            }
        }
    });
}

io.on('connection', (socket) => {
    console.log('📡 Neuro-Cockpit Connected');
    socket.on('execute', (command) => runAutonomousPipeline(command, socket));
});

server.listen(port, '0.0.0.0', () => {
    console.log(`\n===================================================`);
    console.log(`🧠 Gemini Neuro-Bridge v3.1: Windows-Native Patched`);
    console.log(`===================================================\n`);
});
