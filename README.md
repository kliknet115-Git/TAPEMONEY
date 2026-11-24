# TAPEMONEY 💳📲

> **Aplikasi Native iOS untuk Membaca Kartu Uang Elektronik (e-Money) via Core NFC**  
> Dibuat berdasarkan spesifikasi teknis **PRD v2.0 (TapSaldo / TAPEMONEY)**.

---

## 📌 Ringkasan Produk

**TAPEMONEY** adalah aplikasi native iPhone untuk membaca informasi saldo dan catatan riwayat transaksi kartu uang elektronik dengan cara menempelkan (*tap*) kartu fisik ke area sensor NFC di bagian belakang iPhone.

Aplikasi ini menargetkan 4 penerbit kartu e-money utama di Indonesia:
1. **BCA Flazz** (Kandidat Pilot: Flazz Gen 2 berbasis ISO 7816 / MIFARE Desfire)
2. **Mandiri e-money** (Versi 2.0 ISO 7816)
3. **BNI TapCash** (Gen 2 ISO 7816)
4. **BRI BRIZZI** (Gen 2 ISO 7816)

> [!IMPORTANT]
> **Prinsip Utama TAPEMONEY:**
> - **Read-Only:** Aplikasi tidak melakukan top-up, pemotongan saldo, pembayaran, atau penulisan apapun ke chip kartu.
> - **Zero Server / Local-First:** Tidak ada backend server, tidak ada login akun, tidak ada analitik pihak ketiga. Semua data tersimpan lokal di dalam sandbox iPhone Anda.
> - **Status Terpisah:** Saldo dan riwayat memiliki status kompatibilitas terpisah (*success*, *unavailable*, *unsupported version*, *not verified*).

---

## 📱 Tech Stack & Arsitektur

| Komponen | Spesifikasi |
|---|---|
| **Platform** | iOS 17.0+ (iPhone dengan sensor NFC) |
| **Bahasa** | Swift 5.9+ |
| **UI Framework** | SwiftUI (Modern Declarative, `@Observable`, NavigationStack) |
| **NFC Engine** | Apple Core NFC (`NFCTagReaderSession`, ISO 7816 APDU) |
| **Arsitektur** | MVVM + Repository Pattern |
| **Penyimpanan Lokal** | SwiftData (`CardProfile`, `ScanRecord`, `TransactionRecord`) |
| **Ekspor Data** | CSV Export via iOS ShareSheet |

### Struktur Proyek

```text
TAPEMONEY/
├── TAPEMONEY.xcodeproj/         # Xcode Project File
├── TAPEMONEY/
│   ├── App/
│   │   └── TAPEMONEYApp.swift   # Main App Entry & ModelContainer
│   ├── Models/
│   │   ├── CardIssuer.swift             # Enum Penerbit (BCA, Mandiri, BNI, BRI)
│   │   ├── CompatibilityStatus.swift    # Status Saldo & Histori Terpisah
│   │   ├── CardProfile.swift            # SwiftData Model Profil Kartu
│   │   ├── ScanRecord.swift             # SwiftData Model Riwayat Scan
│   │   ├── TransactionRecord.swift      # SwiftData Model Catatan Transaksi
│   │   ├── DetectedNFCTag.swift         # Abstraksi Tag NFC Core NFC
│   │   └── CardReadResult.swift         # Hasil Pembacaan Adapter
│   ├── NFC/
│   │   ├── NFCScanCoordinator.swift     # Koordinator NFCTagReaderSession
│   │   ├── EMoneyCardAdapter.swift      # Protokol Kontrak Adapter Kartu
│   │   ├── CardAdapterRegistry.swift    # Registry Pemilih Adapter
│   │   ├── APDU/
│   │   │   ├── APDUCommand.swift        # Pembentuk Perintah ISO 7816
│   │   │   └── APDUResponse.swift       # Parser Respons Status Word (SW1/SW2)
│   │   ├── Adapters/
│   │   │   ├── BCAFlazzAdapter.swift    # Pilot Adapter BCA Flazz Gen 2
│   │   │   ├── MandiriEMoneyAdapter.swift# Adapter Mandiri e-money
│   │   │   ├── BNITapCashAdapter.swift  # Adapter BNI TapCash
│   │   │   ├── BRIBrizzIAdapter.swift   # Adapter BRI BRIZZI
│   │   │   └── UnknownCardAdapter.swift # Fallback Tag Tak Dikenal
│   │   └── Mock/
│   │       └── MockNFCData.swift        # Data Simulasi Pengujian
│   ├── Services/
│   │   ├── CardDataRepository.swift     # CRUD Repository SwiftData
│   │   └── CSVExportService.swift       # Layanan Ekspor Riwayat ke CSV
│   ├── ViewModels/
│   │   ├── HomeViewModel.swift
│   │   ├── ScanViewModel.swift
│   │   ├── CardListViewModel.swift
│   │   ├── HistoryViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Views/
│   │   ├── MainTabView.swift            # Tab Navigasi Utama
│   │   ├── Home/                        # Beranda & Quick Scan
│   │   ├── Scan/                        # Scanning Sheet & Halaman Hasil
│   │   ├── Cards/                       # Daftar & Detail Kartu Tersimpan
│   │   ├── History/                     # Riwayat Scan & Ekspor CSV
│   │   ├── Settings/                    # Diagnostik & Matriks Kompatibilitas
│   │   └── Components/                  # CardVisualView, StatusPill, dll.
│   └── Resources/
│       ├── Info.plist                   # NFC Usage Description & AID List
│       ├── TAPEMONEY.entitlements       # Tag & NDEF Formats Entitlement
│       └── Assets.xcassets/             # AppIcon & Colors
└── docs/                                # GitHub Pages Landing Page & Privacy
```

---

## 🎯 Matriks Kompatibilitas Kartu

| Kartu | Generasi Target | Status Saldo | Status Riwayat | Catatan Protokol |
|---|---|---|---|---|
| **BCA Flazz** | Gen 2 | ✅ Didukung | ✅ Didukung (Maks 10) | ISO 7816 APDU / Desfire EV2. AID `A000000177000101` |
| **BCA Flazz** | Gen 1 | ❌ Belum Didukung | ❌ Tidak Tersedia | Mifare Classic proprietary (memerlukan hardware SAM) |
| **Mandiri e-money** | Versi 2.0 | ✅ Didukung | ⚠️ Tergantung Kartu | ISO 7816 AID `A0000000040001` |
| **BNI TapCash** | Gen 2 | ✅ Didukung | ⚠️ Tergantung Kartu | ISO 7816 AID `A0000000050001` |
| **BRI BRIZZI** | Gen 2 | ✅ Didukung | ⚠️ Tergantung Kartu | ISO 7816 AID `A0000000060001` |

---

## 🚀 Panduan Menjalankan & Memasang di iPhone

### 💡 PENTING: Anda Pengguna Windows dan Tidak Punya Mac?
Tenang, Anda **TIDAK PERLU MAC**! Proyek ini sudah dilengkapi dengan **GitHub Actions CI/CD** yang menggunakan server cloud macOS gratis dari GitHub:

#### Alur Pemasangan Tanpa Mac (Sideload via Windows):
1. **Push proyek ini ke repositori GitHub Anda**:
   ```bash
   # Di Command Prompt / Terminal Windows:
   git remote add origin https://github.com/USERNAME_ANDA/TAPEMONEY.git
   git branch -M main
   git push -u origin main
   ```
2. **GitHub Actions otomatis meng-compile aplikasi**:
   - Buka repositori Anda di browser GitHub.
   - Klik tab **Actions** di bagian atas.
   - Anda akan melihat workflow **Build TAPEMONEY iOS IPA** berjalan di server macOS GitHub (memakan waktu ~2-3 menit).
   - Setelah selesai, klik run tersebut dan unduh berkas **`TAPEMONEY-iOS-IPA`** (berisi file `TAPEMONEY.ipa`).
3. **Install file `.ipa` ke iPhone dari PC Windows menggunakan Sideloadly**:
   - Download dan buka software gratis **[Sideloadly](https://sideloadly.io/)** di Windows.
   - Hubungkan iPhone Anda ke laptop Windows dengan kabel USB (tekan "Trust This Computer" di iPhone jika diminta).
   - Drag & drop file `TAPEMONEY.ipa` ke aplikasi Sideloadly.
   - Masukkan Apple ID gratis Anda (email Apple ID Anda).
   - Klik tombol **Start**. Sideloadly akan secara otomatis menandatangani aplikasi dengan sertifikat gratis Apple dan menginstalnya langsung ke layar iPhone Anda!
4. **Verifikasi Developer di iPhone**:
   - Di iPhone Anda, buka **Settings (Pengaturan)** > **General (Umum)** > **VPN & Device Management (Manajemen Perangkat)**.
   - Pilih Apple ID Anda, lalu ketuk **Trust (Percayai)**.
   - Aktifkan **Developer Mode** (di iOS 16+) melalui `Settings` > `Privacy & Security` > `Developer Mode` > `On` (iPhone akan restart sekali).
   - Buka aplikasi **TAPEMONEY** dan siap tap kartu e-money Anda!

---

### Cara Alternatif (Jika Memiliki Komputer Mac):
1. Buka folder proyek di Mac Anda:
   ```bash
   open TAPEMONEY.xcodeproj
   ```
2. Pilih target **TAPEMONEY** > tab **Signing & Capabilities**:
   - Pilih **Personal Team** (Apple ID Anda).
   - Pastikan capability **Near Field Communication Tag Reading** aktif.
3. Hubungkan iPhone fisik dan tekan **Cmd + R** (Run).

---

## 📄 Lisensi & Privasi

- **Pribadi & Non-Komersial**: Aplikasi ini dibuat untuk penggunaan pribadi.
- **Kebijakan Privasi**: Baca [docs/privacy.html](file:///c:/Users/User/Documents/EDIDOC/BELAJAR%20VIBE%20CODING/TAPEMONEY/docs/privacy.html) untuk rincian kebijakan privasi offline.
