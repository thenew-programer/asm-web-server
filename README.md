# Assembly HTTP Server

## 🛠️ Project: Minimal HTTP Server in x86_64 Assembly
This is a simple HTTP/1.0 web server written entirely in x86_64 Linux assembly using intel_syntax. It supports both GET and POST requests:

- `GET` requests serve the contents of a file.

- `POST` requests write the body content to a file, where the file path is taken from the request header.

## 🔧 Features
Pure system calls (no C library).

Handles:

- **Socket** creation, binding, listening, and accepting connections.

- **GET** request: reads file contents and sends them as HTTP response.

- **POST** request: parses body, extracts filename from request, and writes the body to disk.

- Simple HTTP/1.0 compliant response: `"HTTP/1.0 200 OK\r\n\r\n"`.

## 📦 Usage
#### 🧑‍💻 Build
```bash
nasm -f elf64 server.asm -o server.o
ld server.o -o server
```
#### 🚀 Run
```bash
sudo ./server
```
⚠️Requires root privileges to bind to ports (default: 0x5000 = port  80).

## 🧪 Test
```bash
curl http://localhost:20480/hello.txt
curl -X POST http://localhost:20480/hello.txt -d "This is a test!"
```
## 📂 File Structure
- `server.asm`: Main server logic

- Handles request parsing, socket management, forking for each client

- GET/POST handler functions included

## 📚 How It Works
- Accepts TCP connections via raw system calls (`socket`, `bind`, `accept`, etc.)

- Forks for each client

- Reads HTTP request into buffer

- Detects `GET` or `POST` using manual string comparison

- Parses file name from request path

- Uses `open`, `read`, `write`, and `close` syscalls to interact with the file system

## 🤯 Why?
Because... why not? Writing a web server in Assembly is the best way to understand every byte of a protocol, every syscall, and every pain in the stack pointer.
