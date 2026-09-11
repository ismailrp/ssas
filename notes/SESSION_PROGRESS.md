# Session Progress — SSAS Performance Assessment

Terakhir diperbarui: 2026-09-11 (Asia/Bangkok)

## Tujuan akhir

Menyelesaikan assessment performa SSAS berbasis evidence yang mencakup fleet baseline, findings, deep dive, action plan, rekomendasi tuning, risiko, effort, expected benefit, dan metode validasi. Laporan belum boleh dianggap final sebelum runtime XEL terakhir selesai dikumpulkan dan dianalisis.

## Status saat ini

Pekerjaan sedang **HOLD atas permintaan user** karena file XEL tambahan masih akan dikumpulkan. Jangan memfinalisasi findings, ranking runtime, percentile, deep dive, atau action plan sebelum user menyatakan batch XEL sudah lengkap.

### Evidence metadata utama

Evidence terbaru: `evidence/EVSET-005/`

- Collector: `Collect-SSAS.ps1` versi 2.3.
- Windows PowerShell pada collection: 4.0.
- Tabular: 54 database.
- Multidimensional: 2 database.
- Collection metadata valid: 56/56.
- TMSL Tabular valid: 54/54.
- Partition statistics Multidimensional berhasil untuk seluruh partition yang ditemukan AMO.
- Source map otomatis: 64 mapping, 53 model, 8 canonical source database pada 3 canonical SQL Server.
- Source SQL lengkap pada 7 source; `192.168.7.32 / DWH_DM` gagal karena untrusted-domain authentication.
- SQL Agent berhasil pada `BGASVR-DWH-DEV` dan `BGASVR-DWHDV`; `192.168.7.32` gagal karena untrusted-domain authentication.
- DMV Tabular `TMSCHEMA_PARTITION_STATS` dan `TMSCHEMA_REFRESH_POLICIES` unsupported pada seluruh 54 model. Ini bukan defect model.
- Server/database memory usage sengaja `SKIPPED` sesuai safety default.

Manifest penting:

- `evidence/EVSET-005/MANIFEST/summary.json`
- `evidence/EVSET-005/MANIFEST/databases.csv`
- `evidence/EVSET-005/MANIFEST/collection_manifest.csv`
- `evidence/EVSET-005/MANIFEST/coverage.csv`
- `evidence/EVSET-005/MANIFEST/source_map_auto.csv`
- `evidence/EVSET-005/MANIFEST/sql_endpoint_resolution.csv`

### Collector

`Collect-SSAS.ps1` versi 2.3 sudah:

- dapat dijalankan dari folder mana pun;
- kompatibel dengan Windows PowerShell 4.0;
- mengumpulkan Tabular, Multidimensional, runtime snapshot, TMSL, source SQL, dan SQL Agent dalam satu run;
- mengenumerasi partition Multidimensional melalui AMO;
- menjalankan `DISCOVER_PARTITION_STAT` dengan restriction database/cube/measure-group/partition;
- membentuk source map otomatis;
- mengkanonisasi alias SQL menggunakan `SERVERPROPERTY('ServerName')`;
- mendeduplikasi source SQL dan SQL Agent berdasarkan canonical endpoint;
- menggunakan Integrated Security dan meredaksi pola credential;
- bersifat read-only dan tidak melakukan processing, deployment, clear cache, atau perubahan job.

Tidak ada update collector yang wajib sebelum assessment dimulai. Gap akses `192.168.7.32` adalah masalah environment/permission, bukan collector.

Konfigurasi saat ini menargetkan `EVSET-005`. Jangan menjalankan ulang atau menimpa evidence ini tanpa kebutuhan eksplisit.

### XEvent

Parser utama: `Parse-SSASXEvents.ps1`.

Input default:

```text
XEvents/Tabular/*.xel
XEvents/Multidimensional/*.xel
```

Output parser:

```text
results/XEvents/<RunId>/
  parser_manifest.csv
  summary.json
  Tabular/events.csv
  Tabular/queries.csv
  Multidimensional/events.csv
  Multidimensional/queries.csv
```

Parser Tabular mengekstrak ActivityID dari `RequestProperties`, mempropagasikannya melalui RequestID, dan menghubungkan QueryEnd dengan VertiPaq/DirectQuery events. Parser Multidimensional memakai ConnectionID + SPID + timestamp window dan menandai overlap sebagai ambigu.

Batch lama pernah divalidasi sebagai `results/XEvents/VALIDATION-20260911`, tetapi **jangan gunakan hasil tersebut sebagai runtime final** karena user sedang menambahkan XEL baru.

Validasi sementara batch lama:

- Tabular: 3 XEL, 12.779 event, 648 QueryEnd terkorrelasi.
- Multidimensional: 3 XEL dapat dibaca tetapi berisi nol event.
- Runtime sementara hanya mencakup 11 database Tabular dan belum mewakili seluruh fleet.
- Angka sementara seperti P50/P95/P99 dan calon hotspot belum boleh dipindahkan ke laporan final.

## Yang perlu diminta ketika user kembali

Konfirmasi singkat:

1. Semua XEL tambahan sudah selesai disalin.
2. Waktu mulai dan selesai window final.
3. Zona waktu server.
4. Apakah folder mengandung file lama/overlap atau hanya satu continuous window.
5. Apakah workload bisnis utama dan jam sibuk tercakup.

Jika user menyatakan file lengkap, jangan menggunakan state parser lama. Jalankan parser ulang dengan RunId baru.

Contoh:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File 'C:\Projects\sql\ssas\Parse-SSASXEvents.ps1' `
  -RunId 'FINAL-XEL-<YYYYMMDD>'
```

## Urutan kerja setelah XEL lengkap

1. Inventarisasi XEL: nama, ukuran, timestamp, hash, dan potensi overlap/duplikasi.
2. Parse seluruh batch ke RunId baru.
3. Validasi event count, field coverage, database, timestamp range, dan correlation quality.
4. Bedakan file valid kosong dari parsing gagal.
5. Hitung workload baseline per database dan query hash:
   - executions;
   - total duration;
   - P50/P95/P99;
   - maximum duration;
   - CPU;
   - SE query count;
   - FE/SE hanya jika korelasi valid;
   - error count dan concurrency signal yang benar-benar tersedia.
6. Jangan memakai `FEMsDerived = TotalMs - sum(SEMs)` sebagai authoritative jika SE event overlap atau jumlah SE melebihi total. Gunakan `CorrelationQuality`.
7. Korelasikan runtime dengan `EVSET-005`: storage, dictionary, partitions, relationships, static DAX, source SQL, dan SQL Agent history.
8. Pilih maksimal delapan deep-dive candidate berdasarkan gabungan evidence dan dampak workload.
9. Buat laporan final di `REPORTS/` sesuai kontrak AGENTS.md.
10. Jalankan quality gates: traceability, classification, confidence, safety, redaksi, dan before/after validation plan.

## Output final yang harus dibuat

```text
REPORTS/
  01_EXECUTIVE_ASSESSMENT.md
  02_FLEET_SCORECARD.csv
  03_TECHNICAL_ASSESSMENT.md
  04_FINDINGS.csv
  05_OPTIMIZATION_BACKLOG.md
  06_DEEP_DIVE_PLAN.md
  DATABASES/<database>.md
```

Jangan membuat halaman database sehat sebagai filler. Setiap finding penting wajib mempunyai evidence file, classification, confidence, impact, recommendation, benefit, effort, priority, risk, dan validation method.

Gunakan kalimat berikut jika evidence tetap tidak cukup:

> `NOT PROVABLE FROM CURRENT EVIDENCE`

## File panduan

Panduan operasional terbaru: `notes/HOWTO_COLLECT_SSAS_EVIDENCE.md`.

Folder `evidence/`, `results/`, dan `XEvents/` sudah dikecualikan melalui `.gitignore` karena dapat besar dan sensitif.

