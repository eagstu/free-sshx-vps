const http = require("http");
const { execSync, spawn } = require("child_process");
const fs = require("fs");

const PORT = process.env.PORT || 3000;

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

  execSync(command, {
    stdio: "inherit",
    shell: "/bin/sh"
  });
}

function installSshx() {
  console.log("Instalando SSHX...");

  run("npm install -g sshx");
}

function startSshx() {
  if (sshxProcess) {
    console.log("SSHX já está rodando.");
    return;
  }

  console.log("Iniciando SSHX...");

  sshxProcess = spawn("sshx", [], {
    shell: true
  });

  sshxProcess.stdout.on("data", data => {
    const text = data.toString();

    process.stdout.write(text);

    const match = text.match(/https?:\/\/[^\s]+/);

    if (match && !sshxUrl) {
      sshxUrl = match[0];

      console.log("\n==============================");
      console.log("SSHX URL:");
      console.log(sshxUrl);
      console.log("==============================\n");
    }
  });

  sshxProcess.stderr.on("data", data => {
    const text = data.toString();

    process.stderr.write(text);

    const match = text.match(/https?:\/\/[^\s]+/);

    if (match && !sshxUrl) {
      sshxUrl = match[0];

      console.log("\n==============================");
      console.log("SSHX URL:");
      console.log(sshxUrl);
      console.log("==============================\n");
    }
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
        message: "SSHX iniciado"
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
