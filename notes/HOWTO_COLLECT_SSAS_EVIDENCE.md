# How-to: Mengumpulkan Evidence SSAS dari Awal

Panduan ini menjalankan collection evidence read-only untuk:

- SSAS Tabular: `BGASVR-DWH-DEV\SQLTABULAR`
- SSAS Multidimensional default instance: `BGASVR-DWH-DEV`

Entry point utama adalah `Collect-SSAS.ps1`. Script tersebut sudah menggabungkan baseline collector dan DMV tambahan dari `collect_gap_evidence.ps1`. Parser XEvent tetap terpisah karena runtime trace memerlukan approval, waktu reproduksi, filter, dan penghentian session yang terkontrol.

## 1. Safety gate sebelum menjalankan

Dapatkan persetujuan owner untuk akses metadata read-only. Sebisa mungkin jalankan fleet collection di luar jam sibuk.

Collector tidak menjalankan processing, deploy, alter model, clear cache, atau delete object. Pengambilan berikut dinonaktifkan secara default karena berpotensi mahal pada fleet besar:

- server-wide `DISCOVER_OBJECT_MEMORY_USAGE`;
- database-level `DISCOVER_OBJECT_MEMORY_USAGE`;
- Extended Events.

Evidence dapat berisi nama server, query partition, DAX, role, dan metadata sensitif. Simpan folder evidence di lokasi terbatas dan jangan membagikan atau commit tanpa review/redaksi.

## 2. Prasyarat

- Windows PowerShell 4.0 atau lebih baru. Gunakan `powershell.exe`, bukan kewajiban PowerShell Core.
- SSMS/SSDT atau SSAS client libraries yang menyediakan:
  - `Microsoft.AnalysisServices.AdomdClient`;
  - `Microsoft.AnalysisServices`;
  - `Microsoft.AnalysisServices.Tabular` untuk export TMSL.
- Account Windows dengan akses read-only ke kedua instance SSAS.
- Koneksi berhasil dari SSMS ke:
  - `BGASVR-DWH-DEV\SQLTABULAR` sebagai Analysis Services;
  - `BGASVR-DWH-DEV` sebagai Analysis Services.

Jika assembly tidak terdeteksi otomatis, siapkan path ke `Microsoft.AnalysisServices.AdomdClient.dll` untuk parameter `-AdomdClientPath`. Collector akan mencari dependency lain di folder yang sama.

## 3. Validasi konfigurasi

Buka `config.json` dan periksa:

- `assessment_id` harus baru untuk collection dari scratch;
- endpoint Multidimensional harus `BGASVR-DWH-DEV`, tanpa nama instance;
- `databases: ["*"]` berarti seluruh database yang berhasil ditemukan;
- memory usage tetap `false` kecuali ada approval dan alasan khusus;
- timeout default 60 detik dapat dinaikkan secara terukur bila DMV tertentu timeout.

Jangan gunakan kembali `EVSET-001`. Baseline lama harus dipertahankan agar hasil dapat dibandingkan dan tidak tertimpa.

## 4. Jalankan collection baru

Buka Windows PowerShell sebagai account yang sudah diberi akses, kemudian:

```powershell
Set-Location -LiteralPath 'C:\Projects\sql\ssas'

.\Collect-SSAS.ps1 -ConfigPath '.\config.json' -AssessmentId 'EVSET-002'
```

Untuk run berikutnya, gunakan ID baru, misalnya `EVSET-003` atau ID bertanggal yang aman untuk nama folder. Parameter `-AssessmentId` mengalahkan nilai di `config.json`.

Jangan memakai `-Force` untuk collection fresh. Secara default artifact existing dilewati. `-Force` hanya untuk overwrite yang disengaja pada evidence set yang sama setelah target dan dampaknya diperiksa.

Jika ADOMD tidak ditemukan:

```powershell
.\Collect-SSAS.ps1 `
  -ConfigPath '.\config.json' `
  -AssessmentId 'EVSET-002' `
  -AdomdClientPath 'C:\Path\To\Microsoft.AnalysisServices.AdomdClient.dll'
```

## 5. Source SQL evidence (opsional)

Source SQL tidak diperlukan untuk DMV SSAS. Gunakan hanya jika mapping sumber sudah divalidasi. CSV mapping minimal:

```csv
Database,SourceDatabase,SqlServer
Nama Model,DatabaseSumber,SQLSERVER\INSTANCE
```

Kolom `SqlServer` boleh dikosongkan bila satu server default diberikan melalui `-SqlServer`.

```powershell
.\Collect-SSAS.ps1 `
  -ConfigPath '.\config.json' `
  -AssessmentId 'EVSET-002' `
  -SourceMapPath '.\source-map.csv' `
  -SqlServer 'SQLSERVER\INSTANCE'
```

Jangan menaruh username, password, token, atau connection string di source map. Collector memakai Windows Integrated Security dan query read-only.

## 6. Validasi hasil collection

Periksa folder `evidence\EVSET-002\MANIFEST` terlebih dahulu:

1. `databases.csv`: pastikan jumlah database Tabular dan Multidimensional sesuai inventory aktual.
2. `collection_manifest.csv`: telusuri setiap `FAILED`, `QUERY_TIMEOUT`, `QUERY_FAILED_OR_UNSUPPORTED`, dan `SKIPPED`.
3. `coverage.csv`: pastikan coverage diklasifikasikan sebagai `COMPLETE`, `PARTIAL`, `MISSING`, `UNSUPPORTED`, atau `SKIPPED`.
4. `summary.json`: cocokkan assessment ID, collector version, waktu, PowerShell version, dan jumlah database.

Contoh pemeriksaan cepat:

```powershell
$root = 'C:\Projects\sql\ssas\evidence\EVSET-002'
$databases = Import-Csv -LiteralPath (Join-Path $root 'MANIFEST\databases.csv')
$manifest = Import-Csv -LiteralPath (Join-Path $root 'MANIFEST\collection_manifest.csv')

$databases | Group-Object ServerType | Select-Object Name,Count
$manifest | Group-Object Server,ServerType,Status | Select-Object Name,Count
$manifest | Where-Object { $_.Status -notin @('SUCCESS','SUCCESS_EMPTY','SKIPPED') } |
  Select-Object Server,Database,Artifact,Status,Message
```

Catatan: `-notin` tersedia pada Windows PowerShell 4.0. Bila hasil harus dibuka di host yang lebih lama, gunakan beberapa perbandingan `-ne`.

Artifact kosong dengan status `SUCCESS_EMPTY` berarti query berhasil dan menghasilkan nol baris. Artifact `MISSING`, `SKIPPED`, atau `UNSUPPORTED` bukan bukti adanya masalah performa.

Kriteria minimum sebelum assessment:

- kedua server berhasil discovery;
- seluruh database terpilih memiliki metadata dan storage yang dapat didukung versinya;
- TMSL Tabular tersedia atau gap TOM tercatat;
- Multidimensional mempunyai folder per database dan bukan hanya baris kegagalan discovery;
- tidak ada credential pada CSV, JSON, log, atau source map.

Jika Multidimensional masih gagal, uji koneksi SSMS ke `BGASVR-DWH-DEV` dan pastikan service SSAS default instance aktif, firewall terbuka, serta account memiliki izin discover. Jangan mengganti kembali endpoint ke `BGASVR-DWH-DEV\SQLMULTIDIM` tanpa bukti bahwa named instance tersebut benar-benar ada.

## 7. Runtime profiling setelah fleet assessment

Snapshot `sessions.csv`, `connections.csv`, dan `commands.csv` bukan histori workload dan tidak dapat menghasilkan P50/P95/P99 atau FE/SE timing.

Setelah scorecard memilih maksimal delapan kandidat, ikuti `SSAS_RUNTIME_PROFILING_GUIDE.md` dan file XMLA/parser yang sesuai. XEvent harus memiliki filter database/waktu sempit, retention plan, approval, dan dihentikan segera setelah reproduksi. Clear cache dan processing tidak dilakukan tanpa change window eksplisit.

## 8. Tahap berikutnya

Setelah manifest lolos validasi, jalankan generator assessment terhadap evidence set baru:

```powershell
.\build_assessment.ps1 -EvidenceRoot 'C:\Projects\sql\ssas\evidence\EVSET-002'
```

Laporan harus tetap membedakan `OBSERVED`, `INFERRED`, dan `REQUIRES VALIDATION`. Bila bukti runtime atau processing belum tersedia, gunakan:

> `NOT PROVABLE FROM CURRENT EVIDENCE`

