# 🚀 QuickDeploy CLI

**QuickDeploy**, projelerinizin derleme (build), sürüm kontrolü (Git) ve FTP üzerinden sunucuya dağıtım (deployment) süreçlerini tek bir terminal komutuyla otomatikleştiren melez (Bash + Node.js) bir komut satırı aracıdır.

Zaman kaybettiren manuel FTP yüklemelerine son vermek için tasarlanmıştır. İçerisindeki akıllı hash algoritması sayesinde tüm projeyi değil, **sadece üzerinde değişiklik yapılmış dosyaları** tespit eder ve sunucuya yalnızca bunları gönderir.

## ✨ Temel Özellikler

*   **Akıllı Yükleme (Hash Kontrolü):** Dosyaların MD5 hash'lerini tutarak yalnızca değişen dosyaları bulur. Bu sayede gigabaytlarca veriyi tekrar tekrar yüklemekten kurtarır.
*   **Tam Otomasyon:** Tek bir komutla (`yayinla`); Git commit atar, projeyi derler ve sunucuya gönderir.
*   **Çoklu Platform ve Dil Desteği:** Next.js, React, Vue, PHP veya düz HTML fark etmeksizin dışa aktarım (`out`/`build`) yapılan tüm projelerle çalışır.
*   **Güvenli Yapılandırma:** FTP şifrelerinizi ve sunucu bilgilerinizi kodun içinde değil, Git tarafından yok sayılan (`.gitignore`) `.deploy.env` dosyasında güvenle saklar.
*   **Dışlanan Dizinler:** `node_modules`, `db`, `.git` gibi sunucuya gitmemesi gereken klasörleri otomatik olarak filtreler.

---
## 📦 Kurulum

**1. Depoyu bilgisayarınıza klonlayın:**
``` bash
git clone https://github.com/mustaf4-saglam/quickdeploy.git
```
``` bash
cd quickdeploy
```
## 2. Gerekli Node.js bağımlılıklarını (basic-ftp, dotenv) yükleyin: 
``` bash npm install ```

3. Bash betiğine çalıştırma (execute) yetkisi verin:
```bash chmod +x quickdeploy.sh```
⚙️ Yapılandırma (İlk Kullanım)Aracı kullanmaya başlamadan önce projenize özel ayarları yapmanız gerekir. Terminalde aşağıdaki komutu çalıştırarak yapılandırma sihirbazını başlatın:
``` bash ./quickdeploy.sh ayarla ```
Sihirbaz size proje adınızı, derleme komutunuzu (örn: npm run build), çıktı klasörünüzü ve FTP bilgilerinizi soracaktır. Girilen bu bilgiler güvenli bir şekilde .deploy.env dosyasına kaydedilir.
Not: .deploy.env dosyası hassas veriler (şifreler) içerdiği için repoya gönderilmemesi adına otomatik olarak .gitignore listesine eklenir.🚀
Yalnızca değiştirdiğiniz 3-5 dosyayı tespit edip FTP'ye saniyeler içinde yükler.📄
