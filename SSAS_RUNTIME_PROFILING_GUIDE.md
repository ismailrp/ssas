# Panduan Runtime Profiling SSAS Tabular

Panduan ini ditujukan untuk mengukur bottleneck runtime pada database yang sudah dipilih oleh `DeepDiveRecommended = TRUE` atau yang memiliki dampak bisnis tinggi. Tujuannya bukan mengumpulkan semua query di server, tetapi memperoleh sampel kecil yang dapat dibandingkan.

## 1. Hasil yang ingin diperoleh

| Hasil | Alat | Nilai yang diperoleh |
|---|---|---|
| Query duration server-side | DAX Studio Server Timings | Total duration, Storage Engine time, jumlah SE queries, dan indikasi Formula Engine work |
| Query plan | DAX Studio Query Plan | Logical/physical plan dan callback/iterator yang perlu ditinjau |
| Query dari report nyata | DAX Studio All Queries atau Performance Analyzer | DAX query yang benar-benar dikirim oleh Power BI/Excel |
| Refresh duration | SSAS Extended Events + processing log | Waktu command/partition processing, progress, error, dan ukuran proses |
| Histori workload | Extended Events yang disimpan terbatas | Database, query, duration, CPU/event, dan waktu kejadian selama window observasi |

Server Timings dan FE/SE **tidak dihitung dari metadata**. Keduanya harus diperoleh dengan menjalankan query. Angka duration dipengaruhi cache, concurrency, result-set size, dan kondisi server saat pengukuran.

## 1A. Arti score yang digunakan

Score berikut berasal dari `02_FLEET_SCORECARD.csv` dan dipakai untuk memilih prioritas profiling. Score tersebut **bukan hasil Server Timings** dan tidak menyatakan durasi dalam milidetik.

| Score/flag | Arti | Cara membaca |
|---|---|---|
| `ComplexityScore` | Risiko relatif karena banyaknya tabel, kolom, measure, dan calculated column. | Tinggi berarti model lebih kompleks dibanding model lain dalam fleet. |
| `StorageScore` | Risiko relatif dari `USED_SIZE`, dictionary size, dan jumlah row terbesar. | Tinggi berarti potensi footprint VertiPaq/scan lebih besar dibanding fleet. |
| `PartitionScore` | Indikasi risiko desain partition, terutama tabel besar dengan partition sedikit atau tidak ada. | Tinggi berarti perlu validasi refresh scope; bukan bukti refresh lambat. |
| `RelationshipScore` | Risiko relatif dari jumlah relationship ditambah penalti bidirectional dan possible many-to-many. | Tinggi berarti filter propagation perlu ditinjau; bukan bukti FE lambat. |
| `DAXRiskScore` | Risiko statis dari jumlah pattern DAX tertentu dan measure dengan sedikitnya dua pattern hit. | Tinggi berarti kandidat measure perlu diprofilkan; bukan bukti query lambat. |
| `OverallScore` | Gabungan lima score kategori. | 0–100; semakin tinggi semakin diprioritaskan untuk investigasi. Bobot: complexity 22,22%, storage 27,78%, partition 16,67%, relationship 16,67%, DAX 16,67%. |
| `RiskLevel` | Label `OverallScore`. | `<30 LOW`, `30–59 MEDIUM`, `60–79 HIGH`, `>=80 CRITICAL`. |
| `Priority` | Prioritas tindak lanjut dari `OverallScore`. | `<30 P3`, `30–59 P2`, `60–79 P1`, `>=80 P0`. |
| `DeepDiveRecommended` | Penanda maksimal delapan model dengan `OverallScore` tertinggi. | `TRUE` berarti kandidat awal runtime profiling, bukan pasti bermasalah. |
| `RuntimeRiskProxy` | Label tambahan yang boleh dibuat dari indikator metadata/runtime tidak lengkap. | Hanya `LOW/MEDIUM/HIGH/UNKNOWN`; jangan diisi dengan estimasi detik atau persentase FE/SE. |

### Nilai yang dihasilkan oleh runtime profiling

Runtime profiling menghasilkan metrik pengukuran, bukan score struktural:

| Metrik | Arti |
|---|---|
| `TotalMs` | Waktu pemrosesan query di server dari event query selesai. |
| `FormulaEngineMs` | Waktu yang tercatat untuk Formula Engine, bila tersedia pada trace. |
| `StorageEngineMs` | Waktu yang tercatat untuk Storage Engine. |
| `FE_share` | `FormulaEngineMs / TotalMs`; proporsi waktu FE terhadap total. |
| `SE_share` | `StorageEngineMs / TotalMs`; proporsi waktu SE terhadap total. |
| `SEQueries` | Jumlah storage-engine request yang tertangkap. |
| `QueryP50Ms` / `QueryP95Ms` | Median/persentil-95 dari beberapa run query yang comparable. |
| `RefreshP50Ms` | Median durasi refresh dari beberapa siklus yang comparable. |

`FE_share` dan `SE_share` adalah rasio observasi, bukan risk score universal. FE 70% tidak otomatis buruk dan SE 70% tidak otomatis baik; interpretasinya harus dibandingkan dengan baseline query yang sama, cache mode, filter context, dan kondisi server yang sebanding.

Contoh klasifikasi evidence:

```text
OverallScore = 82       -> kandidat prioritas CRITICAL
DAXRiskScore = 75       -> static DAX risk tinggi
TotalMs = 4.800 ms      -> hasil pengukuran query
FE_share = 0,68         -> 68% waktu tercatat pada FE
RuntimeEvidenceStatus = CONFIRMED / NOT_REPRODUCED / INCONCLUSIVE
```

Contoh tersebut tidak berarti `OverallScore = 82` menyebabkan query 4.800 ms. Kedua nilai berasal dari sumber berbeda: score dari metadata fleet, sedangkan duration dan FE share dari runtime trace.

## 2. Persiapan dan aturan aman

1. Profiling dilakukan pada 8 database teratas atau database yang memiliki keluhan pengguna terlebih dahulu.
2. Minta hak akses minimum yang diperlukan dari administrator SSAS. Tombol trace DAX Studio biasanya membutuhkan hak server administrator.
3. Jalankan pengukuran di luar jam sibuk jika akan melakukan cold-cache test atau refresh test.
4. Jangan menjalankan `ProcessFull`, clear cache, atau perubahan partition hanya untuk profiling tanpa window perubahan yang disetujui.
5. Catat server, database, waktu, compatibility level, mode cache, nama report, nama query, dan perubahan yang sedang berlangsung.
6. Jangan menyimpan data hasil query yang sensitif. Simpan metrik dan query hash/nama bila query text mengandung data bisnis atau parameter sensitif.

## 3. Menentukan sampel query

Untuk setiap database prioritas, pilih 3–5 query:

- satu visual KPI utama;
- satu tabel/matriks dengan banyak dimensi;
- satu query dengan filter tanggal/range besar;
- satu query yang dirasakan lambat oleh pengguna;
- satu query yang memakai measure dengan `DAXRiskScore` tinggi, bila ada.

Prioritaskan query yang nyata dari Power BI Performance Analyzer atau Excel. Jangan menggunakan query buatan yang tidak mewakili pola pemakaian hanya untuk mendapatkan angka yang bagus.

## 4. Opsi A — Profiling query dengan DAX Studio

### 4.1 Menangkap query dari Power BI

1. Buka report Power BI Desktop.
2. Pilih **Optimize > Performance Analyzer**.
3. Mulai recording, jalankan ulang halaman/visual yang bermasalah, lalu salin DAX query dari visual tersebut.
4. Buka DAX Studio dan connect ke model/report yang sama, atau ke server SSAS Tabular yang menjadi sumbernya.
5. Pilih database/model yang benar dan pastikan query dapat dijalankan.

### 4.2 Menjalankan Server Timings

1. Tempel DAX query pada editor DAX Studio.
2. Aktifkan **Server Timings**.
3. Aktifkan **Query Plan** jika ingin melihat logical dan physical plan.
4. Jalankan query dengan output **Results** atau **Timer Results**.
5. Simpan hasil atau screenshot panel Server Timings sebelum menjalankan query berikutnya.

Kolom yang dicatat minimal:

```text
RunId, Server, Database, QueryName, StartTime, CacheMode,
TotalMs, FormulaEngineMs, StorageEngineMs, SEQueries,
SECPUms, RowsReturned, Notes
```

Catatan: total time dari Server Timings adalah waktu pemrosesan di server dan tidak sama dengan waktu yang dirasakan client karena transfer dan rendering result set dapat menambah waktu client.

### 4.3 Warm-cache dan cold-cache

Untuk setiap query:

1. Jalankan satu kali sebagai warm-up dan jangan masukkan hasilnya ke baseline.
2. Jalankan 3 kali pada kondisi normal/warm cache.
3. Catat median (`P50`) dari 3 run; simpan minimum dan maksimum sebagai konteks.
4. Cold-cache test hanya dilakukan pada jam yang disetujui administrator karena dapat mempengaruhi cache model dan pengguna lain.
5. Jika cold-cache perlu dilakukan, jalankan satu run cold dan ulangi minimal dua run warm setelahnya.

Jangan membandingkan satu cold run dengan satu warm run lalu menyebut perbedaannya sebagai dampak perubahan model.

### 4.4 Interpretasi sederhana

```text
FE_share = FormulaEngineMs / TotalMs
SE_share = StorageEngineMs / TotalMs
```

Gunakan pembacaan berikut sebagai indikasi awal:

| Observasi | Interpretasi awal | Tindakan |
|---|---|---|
| TotalMs tinggi, SE dominan | Scan/volume/storage atau filter data mungkin dominan | Periksa kolom yang discan, dictionary, cardinality, filter selectivity, dan model storage |
| TotalMs tinggi, FE dominan | Iterator, context transition, callback, atau relationship path mungkin dominan | Periksa query plan dan measure; ubah hanya setelah semantic regression test |
| SEQueries sangat banyak | Query terpecah menjadi banyak storage request | Periksa measure, filter context, relationship, dan visual yang terlalu kompleks |
| Cold jauh lebih lambat daripada warm | Cache berpengaruh | Bandingkan query pada cache mode yang sama |
| Hasil tidak stabil antar-run | Concurrency, cache, atau workload berubah | Ulangi pada window yang sama dan tandai sebagai inconclusive bila perlu |

Tidak ada ambang universal seperti “FE > 50% pasti buruk”. Gunakan baseline antar-query atau sebelum/sesudah perubahan pada database yang sama.

## 5. Opsi B — Menangkap query dari client lain

Jika query lambat terjadi di Power BI Service, Excel, atau aplikasi lain:

1. Gunakan fitur **All Queries** di DAX Studio.
2. Connect ke instance/model yang sesuai.
3. Mulai trace hanya selama reproduksi masalah.
4. Minta pengguna menjalankan satu halaman report atau satu tindakan yang sudah ditentukan.
5. Hentikan trace segera setelah query target tertangkap.
6. Filter berdasarkan database, waktu, user/session, atau pola query.

Jangan membiarkan All Queries trace aktif sepanjang hari tanpa retention dan filter karena volume event dapat besar dan berisiko mengekspos query text.

## 6. Opsi C — Profiling refresh dengan Extended Events

Server Timings DAX tidak mengukur refresh. Untuk refresh, buat Extended Events trace/session di SSMS atau tool administrasi SSAS pada instance Analysis Services.

### Event yang disarankan

Pilih event yang tersedia pada versi SSAS Anda:

```text
CommandBegin
CommandEnd
ProgressReportBegin
ProgressReportEnd
QueryBegin
QueryEnd
Error
ResourceUsage                 -- bila tersedia
VertiPaqSEQueryBegin/End      -- bila tersedia dan memang diperlukan
```

Batasi event dengan database/model atau waktu pengukuran jika UI mendukung. Untuk refresh, fokuskan pada `Command*`, `ProgressReport*`, dan `Error`; jangan langsung mengaktifkan semua event.

### Prosedur pengukuran refresh

1. Catat database, model, jenis processing (`ProcessFull`, `ProcessData`, `ProcessAdd`, dan lain-lain), partition target, row count awal, dan waktu mulai.
2. Mulai trace beberapa menit sebelum refresh.
3. Jalankan refresh melalui job/orchestrator normal; jangan mengubah mode processing untuk eksperimen awal.
4. Tunggu `CommandEnd`/progress selesai dan pastikan event error ikut diperiksa.
5. Hentikan trace segera setelah refresh selesai.
6. Simpan start/end time, elapsed duration, partition/table, status, error, dan bila tersedia rows processed.

Format ringkas hasil refresh:

```text
RunId, Server, Database, Model, Partition, ProcessType,
StartTime, EndTime, DurationMs, RowsProcessed, Status, Error, Notes
```

Ambil minimal 2–3 refresh normal untuk database prioritas. Untuk P50/P95, diperlukan histori lebih panjang; satu refresh hanya merupakan snapshot.

## 7. Pengukuran tanpa mengumpulkan semua runtime data

Gunakan desain minimum berikut:

| Tahap | Scope | Beban relatif |
|---|---|---|
| Metadata DMV | Semua database | Rendah; dilakukan satu kali per collection |
| DAX profiling | 8 database teratas × 3–5 query × 3 warm run | Terbatas dan terarah |
| Refresh profiling | Hanya P0/P1 atau database dengan PartitionScore tinggi | Satu-dua siklus normal |
| All Queries/XE workload | Hanya saat reproduksi isu | Window pendek, filter ketat |

Dengan pola ini, tidak perlu merekam seluruh workload fleet untuk memperoleh validasi awal terhadap kandidat teratas.

## 8. Template interpretasi hasil

Gunakan template berikut pada setiap database:

```text
Database:
Profiling window:
Server / model:
Query count:
Refresh run count:

Query result:
- Slowest query / TotalMs:
- Median warm TotalMs:
- FE share:
- SE share:
- SEQueries:
- Stability: STABLE / VARIABLE / INCONCLUSIVE

Refresh result:
- Median duration:
- Longest partition/command:
- Rows processed:
- Error/retry:
- Comparison with previous run:

Finding status:
- CONFIRMED BY RUNTIME
- STRUCTURAL RISK ONLY
- NOT REPRODUCED
- INSUFFICIENT SAMPLE

Next action:
```

## 9. Cara mengubah hasil menjadi evidence scorecard

Tambahkan file evidence baru tanpa menimpa hasil metadata:

```text
evidence/EVSET-001/RUNTIME/<Database>/query_timings.csv
evidence/EVSET-001/RUNTIME/<Database>/query_plans.txt
evidence/EVSET-001/RUNTIME/<Database>/refresh_timings.csv
evidence/EVSET-001/RUNTIME/<Database>/trace_metadata.csv
```

Scorecard dapat ditingkatkan dengan kolom runtime baru seperti:

```text
QueryP50Ms
QueryP95Ms
RefreshP50Ms
FEShareMedian
SEShareMedian
RuntimeEvidenceStatus
```

Namun nilai tersebut harus berasal dari pengukuran yang benar-benar dikumpulkan. Metadata seperti jumlah tabel, row count, atau dictionary size hanya boleh dipakai sebagai `RuntimeRiskProxy`, bukan sebagai pengganti Server Timings atau FE/SE.

## 10. Troubleshooting singkat

| Gejala | Kemungkinan penyebab | Solusi |
|---|---|---|
| Tombol Server Timings/Query Plan disabled | Hak akses trace tidak cukup atau koneksi bukan SSAS Tabular | Minta hak yang sesuai dan pastikan koneksi langsung ke Analysis Services |
| Query tidak dapat dijalankan | DAX bergantung pada filter/report context atau model berbeda | Ambil ulang query dari report yang sama dan connect ke model yang benar |
| Hasil duration berubah-ubah | Cache/concurrency/workload berubah | Gunakan beberapa run, catat cache mode, dan ukur pada window stabil |
| Progress refresh tidak lengkap | Event/version tidak tersedia atau filter terlalu ketat | Jalankan `SELECT * FROM $SYSTEM.DISCOVER_COMMANDS` sebagai snapshot dan periksa event yang tersedia di UI XE |
| DAX Studio result time lebih besar dari Server Timings | Waktu transfer/rendering result set | Gunakan Server Timings untuk waktu server; gunakan Timer Results bila tidak memerlukan hasil data |

## 11. Batasan dan kontrol kualitas

- Server Timings adalah pengukuran query tertentu, bukan performa seluruh fleet.
- FE/SE ratio hanya bermakna bila query, cache, filter context, dan kondisi server dapat dibandingkan.
- Refresh duration dipengaruhi source SQL, jaringan, concurrency, processing mode, dan partition design.
- Setiap perubahan optimasi harus diuji dengan semantic result parity, query duration, refresh duration, dan rollback plan.
- Static `DAXRiskScore` atau `PartitionScore` boleh dinaikkan statusnya menjadi `CONFIRMED` hanya setelah runtime evidence mendukungnya.

## Referensi tool

- DAX Studio Server Timings: <https://daxstudio.org/docs/features/traces/server-timings-trace/>
- DAX Studio Query Plan: <https://daxstudio.org/docs/features/traces/query-plan-trace/>
- DAX Studio Run Benchmark: <https://daxstudio.org/docs/features/run-benchmark/>
