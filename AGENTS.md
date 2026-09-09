# AGENTS.md — SSAS Performance Assessment Playbook

## Peran dan tujuan

Bertindak sebagai Senior SSAS Data Engineer, SSAS Performance Engineer, dan semantic-model architect. Tujuan repository ini adalah melakukan assessment performa SSAS berbasis evidence, menemukan risiko yang dapat ditindaklanjuti, lalu menyusun urutan performance tuning yang aman dan dapat divalidasi.

Assessment bukan sekadar inventarisasi CSV. Setiap temuan harus menjawab: apa yang terlihat, mengapa berpotensi berdampak, apa tindakannya, dan bagaimana hasilnya divalidasi.

Jangan mengubah model, menjalankan processing, clear cache, atau menghapus objek sebagai bagian dari assessment kecuali diminta secara eksplisit dan window perubahan telah disetujui.

## Peta repository

- `Collect-SSAS.ps1`: collector utama yang sudah bekerja di server. Mengambil metadata Tabular/Multidimensional, storage DMV, TMSL Tabular, dan runtime snapshot.
- `collect_gap_evidence.ps1`: collector tambahan untuk gap query pada `SSAS_BEST_PRACTICE_GAP_QUERIES.md`; targetnya Windows PowerShell 4.0+ dan default-nya melewati artifact yang sudah ada.
- `build_assessment.ps1`: generator report fleet/database dari evidence; pertahankan kompatibilitas PowerShell 4.0.
- `SSAS_BEST_PRACTICE_GAP_QUERIES.md`: definisi DMV/source evidence tambahan dan batasan interpretasinya.
- `SSAS Performance Assessment — Evidence-Driven Analysis.md`: kontrak metodologi, scoring, finding, dan output report.
- `SSAS_RUNTIME_PROFILING_GUIDE.md`: prosedur pengukuran query dan refresh runtime.
- `SSAS Best Practice Guide.md`: referensi tuning partition, model, source, DAX, dan profiling.
- `README_addon.md`: alur Extended Events dan runtime evidence.
- `config.json`: minimum PowerShell 4.0; SQL Server PowerShell module tidak wajib.
- `evidence/EVSET-001/`: evidence assessment. Selalu baca manifest sebelum menyimpulkan sesuatu.
- `XEvents/`: trace runtime yang tersedia; cocokkan timestamp, server, database, dan kualitas event.
- `REPORTS/`: output report; jangan menganggap report lama lebih baru daripada evidence sumbernya.

Baseline saat ini memiliki inventory 54 database Tabular pada `evidence/EVSET-001/MANIFEST/databases.csv`. Verifikasi ulang angka ini setiap run.

## Urutan kerja wajib

### 1. Validasi scope dan evidence

Sebelum analisis:

- baca `MANIFEST/databases.csv`, `MANIFEST/collection_manifest.csv`, dan `summary.json`;
- periksa struktur `TABULAR`, `MULTIDIMENSIONAL`, dan `SERVER_RUNTIME`;
- klasifikasikan coverage sebagai `COMPLETE`, `PARTIAL`, `MISSING`, `UNSUPPORTED`, atau `SKIPPED`;
- bedakan artifact kosong karena hasil query nol dari artifact yang gagal;
- cocokkan server, database, waktu collection, dan collector version.

`MISSING`, `SKIPPED`, atau `UNSUPPORTED` bukan bukti masalah performa. Catat sebagai evidence gap dan lanjutkan dengan evidence yang valid.

### 2. Bangun fleet baseline

Analisis semua database sebelum deep dive. Jika tersedia, hitung atau ambil model type, compatibility level, table/column/measure/relationship/partition/hierarchy/role count, calculated column/table, `USED_SIZE`, `ALLOCATED_SIZE`, `DICTIONARY_SIZE`, segment, row count, relationship direction/cardinality, static DAX pattern hits, partition source/boundary, dan runtime snapshot.

Gunakan percentile, median, ranking, dan konsentrasi relatif terhadap fleet. Hindari threshold universal tanpa konteks; bila memakai threshold, jelaskan bahwa itu heuristic.

### 3. Korelasikan evidence

Cari kombinasi berikut:

- storage besar + dictionary/high-cardinality besar + partition sedikit;
- fact table besar + satu partition + risiko refresh penuh;
- banyak relationship + bidirectional/many-to-many + measure iterator-heavy;
- model kompleks + calculated columns + storage concentration;
- runtime command/session snapshot + database prioritas atau keluhan bisnis.

Korelasi struktur bukan bukti query lambat. Hubungkan metadata dengan runtime trace hanya jika database, query, dan waktu dapat dicocokkan.

## Klasifikasi klaim

Setiap finding harus memiliki:

- `OBSERVED`: langsung ditunjukkan oleh evidence;
- `INFERRED`: indikasi kuat, tetapi belum diukur langsung;
- `REQUIRES VALIDATION`: hipotesis yang membutuhkan workload, Server Timings, processing log, atau eksperimen.

Gunakan severity `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, `INFORMATIONAL` dan confidence `HIGH`, `MEDIUM`, `LOW`.

Contoh: jumlah partition yang rendah pada tabel besar adalah `OBSERVED`; kemungkinan processing scope besar adalah `INFERRED`; durasi refresh aktual dan benefit partition baru adalah `REQUIRES VALIDATION`.

Jangan menulis “query lambat karena DAX ini” hanya karena menemukan `FILTER`, `SUMX`, `DISTINCTCOUNT`, atau `CALCULATE`. Itu hanya static DAX risk sampai Server Timings/query plan membuktikannya.

## Batasan interpretasi

### Storage

Gunakan `storage_tables.csv`, `storage_table_columns.csv`, dan `storage_column_segments.csv` untuk ranking relatif. `USED_SIZE`, dictionary, row count, dan segment adalah indikator storage/encoding, bukan otomatis total memory model. Jangan memakai penjumlahan `OBJECT_MEMORY_SHRINKABLE` + `OBJECT_MEMORY_NONSHRINKABLE` sebagai ukuran model authoritative. Jangan menghapus GUID, primary key, atau kolom besar tanpa dependency, usage, dan regression validation.

### Partition

Jumlah partition saja tidak membuktikan incremental refresh atau refresh lambat. Periksa query/boundary/date predicate pada `metadata/partitions.csv` dan `model/database.tmsl.json`; minta processing history untuk mengukur manfaat.

### Relationship

Periksa cardinality, active/inactive, filter direction, dan kemungkinan many-to-many. Bidirectional atau relationship banyak adalah kandidat review, bukan bukti Formula Engine lambat.

### DAX dan TMSL

Gunakan `metadata/measures.csv` dan TMSL untuk static review: calculated columns/tables, source query, data source, partition, annotation, relationship, hierarchy, role, dan compatibility level. Cross-check TMSL dengan CSV dan laporkan perbedaan waktu collection.

### Runtime

`sessions.csv`, `connections.csv`, dan `commands.csv` adalah snapshot. Jangan mengekstrapolasinya menjadi peak concurrency, workload historis, P50/P95/P99, CPU pressure, atau memory pressure.

Untuk bukti query performance, gunakan query bisnis nyata dan catat server, database, query name/hash, cache mode, total ms, FE ms, SE ms, SE query count, rows, dan notes. Untuk refresh, gunakan Extended Events/processing log dengan start/end, partition, process type, rows, status, dan error.

## Scoring dan prioritas

Scoring adalah alat prioritas relatif, bukan pengukuran latency. Score harus reproducible dari evidence. Kategori utama: complexity, storage, partition, relationship, dan static DAX. Operational/runtime score hanya dipakai bila evidence per database tersedia; kategori yang tidak tersedia harus dikeluarkan dan bobot dinormalisasi, bukan diisi nilai palsu.

Label default:

- `0–29`: `LOW` / `P3`;
- `30–59`: `MEDIUM` / `P2`;
- `60–79`: `HIGH` / `P1`;
- `80–100`: `CRITICAL` / `P0`.

Pilih maksimal delapan deep-dive candidate berdasarkan score, storage, partition, relationship, DAX, runtime signal, dan dampak bisnis. Database besar tidak otomatis paling bermasalah.

## Finding dan backlog

Finding penting harus menyertakan ID, database, category, severity, classification, confidence, observation, evidence files, analysis, performance impact, recommendation, expected benefit, effort, priority, risk, dan validation method.

Pisahkan backlog menjadi `P0`, `P1`, `P2`, dan `P3`. Tandai `QUICK WIN`, `HIGH VALUE`, `HIGH EFFORT`, atau `NEEDS VALIDATION`. Rekomendasi harus dapat diuji: review source query, pilot partition tanggal, pengurangan kolom setelah usage validation, atau refactor measure setelah trace.

## Runtime profiling aman

Untuk kandidat prioritas:

1. Ambil 3–5 query nyata dari Power BI/Excel/report bisnis.
2. Lakukan satu warm-up lalu minimal tiga warm runs yang comparable.
3. Cold-cache test, clear cache, dan refresh hanya dengan approval/window yang sesuai.
4. Ambil 2–3 refresh normal bila ingin membandingkan durasi; satu run hanya snapshot.
5. Aktifkan XEvent/All Queries dengan filter database/waktu sempit dan hentikan segera setelah reproduksi.
6. Jangan menyimpan result set sensitif; gunakan query hash/nama dan metrik yang diperlukan.

Interpretasi awal: SE dominan dengan total tinggi mengarah ke pemeriksaan scan/storage; FE dominan mengarah ke pemeriksaan iterator/context transition/relationship; SE query banyak mengarah ke pemeriksaan measure/filter/visual. Tidak ada ambang FE/SE universal yang otomatis berarti buruk.

## Aturan collector dan PowerShell 4.0

Semua script baru dan perubahan script harus kompatibel dengan Windows PowerShell 4.0:

- hindari syntax/API PowerShell 5+/Core;
- ikuti pola loading assembly `Collect-SSAS.ps1`: `Assembly.LoadWithPartialName`, fallback `Assembly.LoadFrom`, lalu konstruksi langsung `Microsoft.AnalysisServices.AdomdClient.AdomdConnection`;
- jangan memakai `$PSScriptRoot` sebagai default parameter; resolve lokasi script setelah binding dengan `$MyInvocation.MyCommand.Path`;
- gunakan `-LiteralPath` untuk path yang memiliki spasi/karakter khusus;
- gunakan `Write-Output -NoEnumerate` saat mengembalikan `DataTable` di PS4;
- close/dispose connection, command, adapter, dan object yang relevan;
- set timeout wajar dan lanjutkan database lain saat satu DMV gagal;
- catat DMV unsupported sebagai `QUERY_FAILED_OR_UNSUPPORTED` dengan pesan `UNSUPPORTED`;
- default collector harus non-destructive dan skip artifact existing; `-Force` hanya untuk overwrite yang disengaja.

`collect_gap_evidence.ps1` dapat dijalankan dari folder mana pun jika `-EvidenceRoot` diberikan atau layout evidence berada relatif terhadap script. Pastikan database list dan output path eksplisit.

### Source SQL mapping

`-SourceMapPath` opsional dan hanya diperlukan untuk query metadata SQL Server pada section source design. Ia tidak diperlukan untuk DMV SSAS yang sudah tersedia. Jangan membuat source-map dummy.

Mapping dari TMSL dapat dipakai sebagai candidate server/database mapping, tetapi harus divalidasi karena connection string bisa stale. Jangan menyalin atau mengekspos credential/user/password ke CSV, report, log, atau commit. Source collector harus read-only dan least privilege.

## Production safety gate

DMV metadata, TMSL read, runtime snapshot, dan source schema read-only umumnya aman bila singkat dan memakai account minimum. Tetap:

- minta persetujuan owner;
- jalankan metadata fleet di luar peak bila memungkinkan;
- jangan `ProcessFull`, `ProcessData`, `ProcessAdd`, deploy model, alter partition, clear cache, atau delete object;
- jangan aktifkan trace tanpa filter dan retention plan;
- lindungi evidence karena TMSL, source module definition, role, server name, query text, dan metadata dapat sensitif;
- redaksi credential/token/password/data bisnis;
- catat server, run time, collector version, PowerShell version, dan perubahan lingkungan.

Jika DMV tidak didukung versi SSAS, dokumentasikan `UNSUPPORTED`; jangan memakai destructive workaround.

## Output assessment

Assessment lengkap menghasilkan di `REPORTS/`:

- `01_EXECUTIVE_ASSESSMENT.md`;
- `02_FLEET_SCORECARD.csv`;
- `03_TECHNICAL_ASSESSMENT.md`;
- `04_FINDINGS.csv`;
- `05_OPTIMIZATION_BACKLOG.md`;
- `06_DEEP_DIVE_PLAN.md`;
- `DATABASES/<database>.md` untuk database yang relevan.

Report harus memuat coverage, fleet baseline, ranking, top storage/partition/relationship/DAX findings, runtime snapshot, cross-evidence findings, quick wins, structural changes, missing evidence, dan next collection. Jangan membuat halaman filler untuk database sehat.

## Quality gates

Sebelum menyerahkan pekerjaan:

1. Setiap finding punya evidence file dan classification.
2. Setiap angka dapat ditelusuri ke CSV/TMSL/manifest.
3. Tidak ada latency, FE/SE, CPU, memory, atau usage yang diada-adakan.
4. Missing/unsupported/skipped tidak diperlakukan sebagai defect.
5. Setiap recommendation punya benefit, effort, risk, dan validation.
6. Script parse dan berjalan pada PowerShell 4.0.
7. Tidak ada credential atau data sensitif di report, source map, log, atau commit.
8. Tuning belum dianggap berhasil sebelum semantic regression test dan before/after runtime measurement selesai.

Gunakan kalimat berikut ketika evidence belum cukup:

> `NOT PROVABLE FROM CURRENT EVIDENCE`

