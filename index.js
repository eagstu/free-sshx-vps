const http = require("http");
const { execSync, spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

const PORT = process.env.PORT || 3000;
const BIN_DIR = path.join(__dirname, "bin");
const SSHX_BIN = path.join(BIN_DIR, "sshx");

let distro = "unknown";
let installing = false;
let installed = false;
let sshxUrl = null;
let sshxProcess = null;

function detectDistro() {
  try {
    const data = fs.readFileSync("/etc/os-release", "utf8");
    const match = data.match(/^ID=(.+)$/m);

    return match
      ? match[1].replace(/"/g, "").toLowerCase()
      : "unknown";
  } catch {
    return "unknown";
  }
}

function run(command) {
  console.log("$", command);

  return execSync(command, {
    stdio: "inherit",
    shell: "/bin/bash"
  });
}

function hasSshx() {
  return fs.existsSync(SSHX_BIN);
}

function installSshx() {
  if (hasSshx()) {
    console.log("SSHX já está instalado.");
    return;
  }

  console.log("Instalando SSHX...");

  fs.mkdirSync(BIN_DIR, {
    recursive: true
  });

  const url =
    "https://s3.amazonaws.com/sshx/sshx-x86_64-unknown-linux-musl.tar.gz";

  const archive = path.join(BIN_DIR, "sshx.tar.gz");

  run(`curl -L "${url}" -o "${archive}"`);

  run(`tar -xzf "${archive}" -C "${BIN_DIR}"`);

  run(`chmod +x "${SSHX_BIN}"`);

  try {
    fs.unlinkSync(archive);
  } catch {}

  console.log(`SSHX instalado em: ${SSHX_BIN}`);
}

function startSshx() {
  if (sshxProcess) {
    console.log("SSHX já está rodando.");
    return;
  }

  console.log("Iniciando SSHX...");

  sshxProcess = spawn(SSHX_BIN, [], {
    env: process.env
  });

  function handleOutput(data) {
    const text = data.toString();

    process.stdout.write(text);

    const match = text.match(/https?:\/\/[^\s"'`]+/);

    if (match && !sshxUrl) {
      sshxUrl = match[0];

      console.log("");
      console.log("==============================");
      console.log("SSHX URL:");
      console.log(sshxUrl);
      console.log("==============================");
      console.log("");
    }
  }

  sshxProcess.stdout.on("data", handleOutput);
  sshxProcess.stderr.on("data", handleOutput);

  sshxProcess.on("error", error => {
    console.error("Erro ao iniciar SSHX:", error.message);

    sshxProcess = null;
  });

  sshxProcess.on("exit", code => {
    console.log(`SSHX finalizado: ${code}`);

    sshxProcess = null;
  });
}

async function install() {
  if (installing) {
    throw new Error("Instalação já está em andamento");
  }

  installing = true;

  try {
    distro = detectDistro();

    console.log("Distro:", distro);

    installSshx();

    installed = true;

    startSshx();
  } finally {
    installing = false;
  }
}

const server = http.createServer(async (req, res) => {
  res.setHeader("Content-Type", "application/json");

  if (req.method === "GET" && req.url === "/health") {
    return res.end(JSON.stringify({
      status: "ok",
      distro,
      installed,
      installing,
      sshxRunning: !!sshxProcess,
      sshxUrl,
      uptime: Math.floor(process.uptime())
    }));
  }

  if (req.method === "POST" && req.url === "/install") {
    try {
      await install();

      return res.end(JSON.stringify({
        success: true,
        message: "SSHX iniciado",
        sshxUrl
      }));
    } catch (error) {
      res.statusCode = 500;

      return res.end(JSON.stringify({
        success: false,
        error: error.message
      }));
    }
  }

  res.statusCode = 404;

  res.end(JSON.stringify({
    error: "Rota não encontrada"
  }));
});

server.listen(PORT, "0.0.0.0", () => {
  distro = detectDistro();

  console.log(`Servidor iniciado na porta ${PORT}`);
  console.log(`Distro detectada: ${distro}`);

  install()
    .then(() => {
      console.log("Inicialização concluída.");
    })
    .catch(error => {
      console.error("Erro:", error.message);
    });
});