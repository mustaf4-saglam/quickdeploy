const ftp = require("basic-ftp");
const path = require("path");
const fs = require("fs");
const crypto = require("crypto");
require("dotenv").config({ path: path.join(__dirname, ".deploy.env") });

const CACHE_FILE = path.join(__dirname, ".deploy-cache.json");

function getFileHash(filePath) {
    const fileBuffer = fs.readFileSync(filePath);
    const hashSum = crypto.createHash("md5");
    hashSum.update(fileBuffer);
    return hashSum.digest("hex");
}

function getFilesRecursively(dir, fileList = []) {
    if (!fs.existsSync(dir)) return fileList;
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const filePath = path.join(dir, file);
        if (fs.statSync(filePath).isDirectory()) {
            getFilesRecursively(filePath, fileList);
        } else {
            fileList.push(filePath);
        }
    }
    return fileList;
}

async function deploy() {
    console.log("🔍 Değişen dosyalar taranıyor...");

    const localDirName = process.env.LOCAL_DIR || "./out";
    const localDir = path.join(__dirname, localDirName);
    const remoteDir = process.env.REMOTE_DIR || "/htdocs";
    const excludeDirs = (process.env.EXCLUDE_DIRS || "db,.git,node_modules").split(",").map(d => d.trim());

    if (!fs.existsSync(localDir)) {
        console.error(` HATA: '${localDirName}' klasörü bulunamadı. Build işleminin başarılı olduğundan emin olun.`);
        process.exit(1);
    }

    let cache = {};
    if (fs.existsSync(CACHE_FILE)) {
        cache = JSON.parse(fs.readFileSync(CACHE_FILE, "utf8"));
    }

    const allFiles = getFilesRecursively(localDir);
    const filesToUpload = [];
    const newCache = {};

    for (const file of allFiles) {
        const isExcluded = excludeDirs.some(ex => file.includes(`/${ex}/`) || file.includes(`\\${ex}\\`));
        if (isExcluded) continue;

        const hash = getFileHash(file);
        const relativePath = path.relative(localDir, file).replace(/\\/g, '/');
        
        newCache[relativePath] = hash;

        if (!cache[relativePath] || cache[relativePath] !== hash) {
            filesToUpload.push({ localPath: file, remotePath: `${remoteDir}/${relativePath}` });
        }
    }

    if (filesToUpload.length === 0) {
        console.log("Değişen hiçbir dosya yok. Sunucu tamamen güncel!");
        fs.writeFileSync(CACHE_FILE, JSON.stringify(newCache, null, 2));
        return;
    }

    console.log(`Sadece değişen ${filesToUpload.length} dosya yüklenecek`);

    const client = new ftp.Client();
    
    try {
        console.log("Sunucuya bağlanılıyor...");
        await client.access({
            host: process.env.FTP_HOST,
            user: process.env.FTP_USER,
            password: process.env.FTP_PASSWORD,
            secure: false
        });
        
        for (let i = 0; i < filesToUpload.length; i++) {
            const fileObj = filesToUpload[i];
            const remoteFilePath = fileObj.remotePath;
            const remoteFileDir = path.dirname(remoteFilePath);
            
            console.log(`[${i+1}/${filesToUpload.length}] Yükleniyor: ${remoteFilePath}`);
            
            await client.ensureDir(remoteFileDir);
            await client.uploadFrom(fileObj.localPath, remoteFilePath);
        }
        
        fs.writeFileSync(CACHE_FILE, JSON.stringify(newCache, null, 2));
        console.log("✅ YÜKLEME TAMAMLANDI!");
    }
    catch(err) {
        console.error(" HATA:", err.message);
    }
    finally {
        client.close();
    }
}

deploy();
