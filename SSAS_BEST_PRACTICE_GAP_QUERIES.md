# Query/DMV untuk Menutup Gap SSAS Best Practice

File ini berisi query read-only untuk melengkapi evidence scorecard. Query DMV SSAS dijalankan di SSMS dengan koneksi ke **Analysis Services** (MDX/XMLA query window), bukan pada koneksi Database Engine SQL Server.

Jalankan query per database/model yang ingin dikumpulkan. Simpan hasil setiap DMV ke CSV dengan nama yang jelas, misalnya `TMSCHEMA_COLUMNS_<Database>.csv`.

## 1. Discovery dan struktur model

Query berikut membantu memvalidasi star schema, snowflake, tipe relationship, dan desain model.

```sql
-- Daftar tabel
SELECT *
FROM $SYSTEM.TMSCHEMA_TABLES;

-- Daftar kolom, tipe data, calculated column, key, dan summarization
SELECT *
FROM $SYSTEM.TMSCHEMA_COLUMNS;

-- Daftar relationship dan arah filter
SELECT *
FROM $SYSTEM.TMSCHEMA_RELATIONSHIPS;
```

Analisis yang dapat dilakukan:

- Cari tabel dimensi yang berelasi ke dimensi lain; ini adalah kandidat snowflake.
- Cari `CROSS_FILTERING_BEHAVIOR` yang menunjukkan filter dua arah.
- Cari cardinality many-to-many.
- Cari kolom `DATETIME`/`DOUBLE`/teks pada fact table.
- Cari calculated column melalui `EXPRESSION` yang tidak kosong.

Untuk mengetahui nama kolom DMV yang tersedia pada versi SSAS tertentu, gunakan:

```sql
SELECT *
FROM $SYSTEM.TMSCHEMA_COLUMNS;
```

Kemudian cocokkan nama field dari header hasil export. Nama field dapat berbeda sedikit menurut versi SSAS/compatibility level.

## 2. Cardinality, dictionary, dan encoding VertiPaq

DMV berikut melengkapi analisis storage dengan level kolom. Ini membantu mencari kolom high-cardinality, dictionary besar, dan encoding yang kurang efisien.

```sql
-- Ringkasan storage per kolom
SELECT *
FROM $SYSTEM.DISCOVER_STORAGE_TABLE_COLUMNS;

-- Detail segment per kolom
SELECT *
FROM $SYSTEM.DISCOVER_STORAGE_TABLE_COLUMN_SEGMENTS;

-- Ringkasan storage per tabel
SELECT *
FROM $SYSTEM.DISCOVER_STORAGE_TABLES;
```

Prioritaskan kolom berdasarkan kombinasi `DICTIONARY_SIZE`, `USED_SIZE`, jumlah record/segment, dan bila tersedia `DISTINCT_COUNT` atau cardinality field. Jangan menghapus primary key/GUID hanya karena besar; validasi dependency dan kebutuhan filter terlebih dahulu.

## 3. Partition, source query, dan boundary

```sql
-- Definisi partition, status, source type, dan query source
SELECT *
FROM $SYSTEM.TMSCHEMA_PARTITIONS;
```

Dari hasil tersebut, cari field yang relevan seperti `TABLE_ID`, `NAME`, `SOURCE_TYPE`, `QUERY_DEFINITION`, `EXPRESSION`, `STATE`, dan `LAST_PROCESSED` bila tersedia.

Untuk implementasi yang mendukung field tersebut, query ringkas berikut dapat digunakan:

```sql
SELECT
    TABLE_ID,
    ID,
    NAME,
    SOURCE_TYPE,
    QUERY_DEFINITION,
    EXPRESSION,
    STATE,
    LAST_PROCESSED
FROM $SYSTEM.TMSCHEMA_PARTITIONS;
```

Jika query ringkas gagal karena field tertentu tidak tersedia, kembali gunakan `SELECT *` dan ambil field yang tersedia dari hasil DMV. Jangan menyimpulkan bahwa partition incremental sudah aktif hanya dari jumlah partition; periksa query filter/boundary tanggal dan kebijakan refresh.

Tambahkan metadata policy jika model menggunakannya:

```sql
SELECT *
FROM $SYSTEM.TMSCHEMA_REFRESH_POLICIES;
```

DMV policy tidak tersedia pada semua versi SSAS. Jika gagal, dokumentasikan sebagai `UNSUPPORTED`, bukan sebagai defect model.

## 4. Measure dan pemeriksaan anti-pattern DAX

```sql
SELECT *
FROM $SYSTEM.TMSCHEMA_MEASURES;
```

Export kolom `NAME`, `TABLE_ID`, dan `EXPRESSION`, lalu cari pola berikut pada expression:

```text
FILTER(ALL(...))
FILTER(ALLSELECTED(...))
SUMX(<large table>, ...)
AVERAGEX(<large table>, ...)
COUNTX(<large table>, ...)
CROSSJOIN(...)
GENERATE(...)
```

Pencarian teks hanya menghasilkan kandidat. Pola tersebut tidak boleh diterjemahkan menjadi durasi query tanpa Server Timings dan pengujian hasil.

## 5. Tipe data dan desain source di SQL Server

Query berikut dijalankan pada **database sumber**, bukan SSAS. Ganti nama schema/table sesuai sumber partition.

```sql
-- Tipe data, panjang, presisi, nullable, dan computed column
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_computed,
    c.is_identity
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
ORDER BY s.name, t.name, c.column_id;
```

```sql
-- Kandidat kolom high-cardinality/operasional berdasarkan ukuran data
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_computed
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('uniqueidentifier','nvarchar','varchar','ntext','text','datetime','datetime2','float','real')
ORDER BY c.max_length DESC, s.name, t.name, c.column_id;
```

```sql
-- View/procedure yang dapat menjadi source query atau materialization candidate
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('V','IF','TF','FN','P')
ORDER BY s.name, o.name;
```

Query ini dapat mengidentifikasi tipe data dan kompleksitas source object, tetapi tidak bisa membuktikan bahwa sebuah kolom tidak digunakan oleh report. Untuk itu tetap diperlukan dependency/usage telemetry.

## 6. DMV runtime ringan: snapshot saja

```sql
-- Snapshot sesi, koneksi, dan command yang sedang terlihat
SELECT * FROM $SYSTEM.DISCOVER_SESSIONS;
SELECT * FROM $SYSTEM.DISCOVER_CONNECTIONS;
SELECT * FROM $SYSTEM.DISCOVER_COMMANDS;
```

DMV ini tidak menyimpan histori yang cukup untuk menghitung P50/P95/P99, FE/SE ratio, atau refresh duration. Query tersebut hanya membantu mengetahui aktivitas pada saat pengambilan snapshot.

## 7. Apa yang masih tidak dapat diperoleh dari DMV metadata

| Target | Kesimpulan |
|---|---|
| Server Timings dalam milidetik | Tidak dapat dihitung dari metadata; harus menjalankan query representatif dan menangkap timing. |
| Formula Engine vs Storage Engine duration/ratio | Tidak tersedia sebagai angka historis dari DMV struktur model. Memerlukan Server Timings/query trace. |
| P50/P95/P99 query duration | Tidak tersedia tanpa telemetry berulang. |
| Refresh duration per database/partition | Tidak dapat direkonstruksi dari jumlah row/partition. Memerlukan processing events atau refresh log. |
| Prediksi angka latency/refresh | Tidak disarankan tanpa baseline historis; gunakan `UNKNOWN` atau risk band, bukan angka detik. |

Pengumpulan runtime tidak harus dilakukan untuk seluruh fleet. Cara hemat waktu:

1. Jalankan DMV metadata di seluruh fleet karena read-only dan relatif ringan.
2. Pilih 8 kandidat `DeepDiveRecommended = TRUE`.
3. Untuk tiap kandidat, ambil 3–5 query bisnis yang representatif, satu cold-cache dan satu warm-cache bila memungkinkan.
4. Ambil satu atau dua siklus refresh untuk model prioritas tinggi, terutama yang memiliki `PartitionScore` tinggi.
5. Gunakan hasil tersebut untuk mengkalibrasi proxy score. Jangan mengganti nilai `Server Timings` atau `FE/SE` dengan estimasi metadata.

## 8. Format evidence yang disarankan

Simpan hasil dengan pola berikut:

```text
evidence/EVSET-001/TABULAR/<Database>/metadata/tmschema_tables.csv
evidence/EVSET-001/TABULAR/<Database>/metadata/tmschema_columns.csv
evidence/EVSET-001/TABULAR/<Database>/metadata/tmschema_relationships.csv
evidence/EVSET-001/TABULAR/<Database>/metadata/tmschema_partitions.csv
evidence/EVSET-001/TABULAR/<Database>/metadata/tmschema_measures.csv
evidence/EVSET-001/TABULAR/<Database>/metadata/refresh_policies.csv
evidence/EVSET-001/TABULAR/<Database>/storage/storage_table_columns.csv
evidence/EVSET-001/TABULAR/<Database>/storage/storage_column_segments.csv
```

Setiap export sebaiknya menyertakan nama server, database, waktu pengambilan, compatibility level, dan status query. DMV yang tidak didukung dicatat sebagai `UNSUPPORTED`; jangan mengisi nilai kosong dengan asumsi nol.
