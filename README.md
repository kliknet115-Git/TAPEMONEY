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

### Persyaratan:
1. Komputer Mac dengan macOS Sonoma / Ventura.
2. Xcode 15.0 atau lebih baru.
3. Apple ID terdaftar (Personal Team gratis atau Apple Developer Program).
4. iPhone fisik dengan iOS 17+ yang mendukung Core NFC (iPhone 7 hingga iPhone 16 series).

### Langkah Build di Xcode:
1. Buka folder proyek di Mac Anda:
   ```bash
   open TAPEMONEY.xcodeproj
   ```
2. Pilih target **TAPEMONEY** di navigasi kiri.
3. Masuk ke tab **Signing & Capabilities**:
   - Pilih **Team** Anda (Personal Apple ID Anda).
   - Pastikan capability **Near Field Communication Tag Reading** aktif.
4. Hubungkan iPhone fisik Anda ke Mac dengan kabel USB.
5. Pilih target perangkat: iPhone Anda.
6. Tekan tombol **Run (Cmd + R)** untuk mem-build dan memasang aplikasi ke iPhone.
7. Di iPhone: Masuk ke `Settings` > `General` > `VPN & Device Management` dan izinkan sertifikat Developer Anda.

### Mode Simulasi (Xcode Simulator)
Untuk kenyamanan pengujian antarmuka tanpa iPhone fisik atau tanpa kartu e-money:
- Jalankan di iOS Simulator.
- Di Beranda, ketuk menu **titik tiga (•••)** di kanan atas.
- Pilih **Simulasi Flazz Gen 2**, **Simulasi Mandiri e-money**, dll.
- Anda dapat menguji seluruh alur pembacaan, tampilan saldo, visual kartu, transaksi, dan penyimpanan lokal!

---

## 📄 Lisensi & Privasi

- **Pribadi & Non-Komersial**: Aplikasi ini dibuat untuk penggunaan pribadi.
- **Kebijakan Privasi**: Baca [docs/privacy.html](file:///c:/Users/User/Documents/EDIDOC/BELAJAR%20VIBE%20CODING/TAPEMONEY/docs/privacy.html) untuk rincian kebijakan privasi offline.
