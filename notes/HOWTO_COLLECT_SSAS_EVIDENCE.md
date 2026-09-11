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

Semua contoh script di panduan ini memakai `-ExecutionPolicy Bypass`. Opsi tersebut hanya berlaku pada proses `powershell.exe` yang sedang dijalankan dan tidak mengubah execution policy mesin secara permanen. Kebijakan organisasi melalui Group Policy tetap dapat mengalahkan opsi ini.

Jika assembly tidak terdeteksi otomatis, siapkan path ke `Microsoft.AnalysisServices.AdomdClient.dll` untuk parameter `-AdomdClientPath`. Collector akan mencari dependency lain di folder yang sama.

## 3. Validasi konfigurasi

Buka `config.json` dan periksa:

- `assessment_id` harus baru untuk collection dari scratch;
- endpoint Multidimensional harus `BGASVR-DWH-DEV`, tanpa nama instance;
- `databases: ["*"]` berarti seluruh database yang berhasil ditemukan;
- memory usage tetap `false` kecuali ada approval dan alasan khusus;
- timeout default 60 detik dapat dinaikkan secara terukur bila DMV tertentu timeout.

Jangan gunakan kembali `EVSET-001`. Baseline lama harus dipertahankan agar hasil dapat dibandingkan dan tidak tertimpa.

## 4. Jalankan collection baru dari folder mana pun

Bawa minimal `Collect-SSAS.ps1` dan `config.json` ke folder yang sama pada server. Semua default path diselesaikan relatif terhadap lokasi script/config, bukan current working directory. Karena itu script dapat dipanggil dari folder mana pun.

Contoh bila package berada di `D:\SSAS-Assessment` tetapi PowerShell sedang berada di folder lain:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File 'D:\SSAS-Assessment\Collect-SSAS.ps1' `
  -ConfigPath '.\config.json' `
  -AssessmentId 'EVSET-004'
```

Dengan contoh tersebut, `config.json` dicari di `D:\SSAS-Assessment` dan `output_root: ".\\evidence"` menghasilkan `D:\SSAS-Assessment\evidence\EVSET-004`.

Untuk run berikutnya, gunakan ID baru, misalnya `EVSET-005` atau ID bertanggal yang aman untuk nama folder. Parameter `-AssessmentId` mengalahkan nilai di `config.json`.

Jangan memakai `-Force` untuk collection fresh. Secara default artifact existing dilewati. `-Force` hanya untuk overwrite yang disengaja pada evidence set yang sama setelah target dan dampaknya diperiksa.

Jika ADOMD tidak ditemukan:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File 'D:\SSAS-Assessment\Collect-SSAS.ps1' `
  -ConfigPath '.\config.json' `
  -AssessmentId 'EVSET-004' `
  -AdomdClientPath 'C:\Path\To\Microsoft.AnalysisServices.AdomdClient.dll'
```

## 5. Auto source map dan Source SQL evidence

Source SQL tidak diperlukan untuk DMV SSAS. Collector otomatis membaca data source dari TMSL dan membuat:

```text
MANIFEST/source_map_auto.csv
```

File tersebut hanya memuat model, nama data source, server SQL, database sumber, dan status discovery. Connection string, username, password, token, dan credential tidak ditulis ke mapping.

Mapping hasil TMSL adalah kandidat, bukan jaminan endpoint masih benar. Collector versi 2.2 membentuk mapping di memori dan langsung mengumpulkan source evidence pada run yang sama melalui:

```json
"source_sql": true
```

Collector mendeduplikasi mapping sehingga setiap kombinasi SQL server/database hanya dikueri sekali dan menyimpan hasil di:

```text
SOURCE_SQL/<server>/<source-database>/
```

Jika diperlukan, `-SourceMapPath` tetap dapat dipakai sebagai override untuk membatasi source tertentu, tetapi file manual tidak lagi wajib. Jangan menaruh credential di source map. Collector memakai Windows Integrated Security dan query read-only.

Karena endpoint TMSL dapat stale, kegagalan koneksi satu source dicatat di manifest dan tidak menghentikan source/database lain. Jika owner belum menyetujui source access, ubah `source_sql` menjadi `false`; auto map tetap dibuat.

### SQL Agent evidence

Collector juga mengumpulkan SQL Agent evidence sekali jalan ketika konfigurasi berikut aktif:

```json
"sql_agent": true,
"sql_agent_history_days": 90
```

Target SQL Agent berasal dari semua server unik pada auto source map ditambah `sql_agent_servers` pada `config.json`. Tambahkan orchestration server ke daftar tersebut bila SQL Agent berada di server yang tidak muncul dalam TMSL.

Output berada di `SQL_AGENT/<server>/msdb/` dan mencakup inventory job, step yang terindikasi menjalankan SSAS, schedule, activity terkini, serta history 90 hari. Account collector memerlukan akses metadata read-only ke `msdb`; collector tidak menjalankan, mengubah, enable/disable, atau menghapus job.

Job command dapat sensitif. Collector melakukan redaksi pola password, token, secret, credential, bearer token, API key, dan user ID sebelum menulis CSV. Tetap lakukan review sebelum evidence dibagikan.

## 6. Validasi hasil collection

Periksa folder `evidence\EVSET-004\MANIFEST` terlebih dahulu:

1. `databases.csv`: pastikan jumlah database Tabular dan Multidimensional sesuai inventory aktual.
2. `collection_manifest.csv`: telusuri setiap `FAILED`, `QUERY_TIMEOUT`, `QUERY_FAILED_OR_UNSUPPORTED`, dan `SKIPPED`.
3. `coverage.csv`: pastikan coverage diklasifikasikan sebagai `COMPLETE`, `PARTIAL`, `MISSING`, `UNSUPPORTED`, atau `SKIPPED`.
4. `summary.json`: cocokkan assessment ID, collector version, waktu, PowerShell version, dan jumlah database.

Contoh pemeriksaan cepat:

```powershell
$root = 'C:\Projects\sql\ssas\evidence\EVSET-004'
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

## 7. Parse file XEL setelah disalin

Salin file XEL tanpa mengubah isinya ke:

```text
XEvents/Tabular/*.xel
XEvents/Multidimensional/*.xel
```

Jalankan parser offline dari folder mana pun:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File 'C:\Projects\sql\ssas\Parse-SSASXEvents.ps1' `
  -RunId 'XEL-20260911'
```

Default input dan output selalu relatif terhadap lokasi `Parse-SSASXEvents.ps1`. Hasil berada di:

```text
results/XEvents/<RunId>/
  parser_manifest.csv
  summary.json
  Tabular/events.csv
  Tabular/queries.csv
  Multidimensional/events.csv
  Multidimensional/queries.csv
```

`events.csv` mempertahankan event-level evidence: timestamp, ActivityID, RequestID, SessionID, ConnectionID, SPID, DatabaseName, DurationMs, CpuTimeMs, NTUserName, TextData, hash teks, dan event subclass.

Pada trace Tabular, ActivityID dapat tersimpan di XML `RequestProperties`, bukan sebagai field event langsung. Parser mengekstraknya dari `DbpropMsmdActivityID`, mempropagasikannya melalui `RequestID`, lalu menghubungkan QueryEnd dengan VertiPaqSEQueryEnd. `queries.csv` berisi total, CPU, jumlah/durasi SE, FE yang diturunkan, serta `CorrelationQuality`.

Untuk Multidimensional, parser memasangkan QueryBegin/QueryEnd dan sub-event berdasarkan `ConnectionID + SPID + timestamp window`. Jika query overlap pada koneksi/SPID yang sama, hasil ditandai `AMBIGUOUS_OVERLAPPING_WINDOW`; metrik sub-event harus diperlakukan sebagai indikatif.

Jika DLL tidak ditemukan otomatis:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File 'C:\Projects\sql\ssas\Parse-SSASXEvents.ps1' `
  -RunId 'XEL-20260911' `
  -XEventDllPath 'C:\Program Files\Microsoft SQL Server\160\Shared\Microsoft.SqlServer.XEvent.Linq.dll'
```

Gunakan RunId baru untuk setiap batch. `-Force` hanya untuk overwrite hasil parsing yang disengaja. File dengan nol event tetap menghasilkan CSV ber-header dan count nol di `summary.json`; ini berarti XEL dapat dibaca tetapi tidak memuat event yang cocok, bukan bukti bahwa server tidak mempunyai masalah performa.

QueryText dan NTUserName adalah data sensitif. Batasi akses folder `results`, dan gunakan hash query ketika teks asli tidak diperlukan untuk laporan.

Parser lama `03_tabular_parser_to_csv.ps1` dan `04_multidimensional_parser_to_csv.ps1` tidak digunakan dalam workflow baru; gunakan `Parse-SSASXEvents.ps1` agar schema dan manifest konsisten.

## 8. Runtime profiling setelah fleet assessment

Snapshot `sessions.csv`, `connections.csv`, dan `commands.csv` bukan histori workload dan tidak dapat menghasilkan P50/P95/P99 atau FE/SE timing.

Setelah scorecard memilih maksimal delapan kandidat, ikuti `SSAS_RUNTIME_PROFILING_GUIDE.md` dan file XMLA/parser yang sesuai. XEvent harus memiliki filter database/waktu sempit, retention plan, approval, dan dihentikan segera setelah reproduksi. Clear cache dan processing tidak dilakukan tanpa change window eksplisit.

## 9. Tahap berikutnya

Setelah manifest lolos validasi, jalankan generator assessment terhadap evidence set baru:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File 'C:\Projects\sql\ssas\build_assessment.ps1' `
  -EvidenceRoot 'C:\Projects\sql\ssas\evidence\EVSET-004'
```

Laporan harus tetap membedakan `OBSERVED`, `INFERRED`, dan `REQUIRES VALIDATION`. Bila bukti runtime atau processing belum tersedia, gunakan:

> `NOT PROVABLE FROM CURRENT EVIDENCE`
