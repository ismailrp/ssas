Berikut adalah rancangan **SOP (Standard Operating Procedure) SSAS Performance Tuning & Best Practices**. Panduan ini telah diubah formatnya menjadi instruksi tindakan yang berfokus pada optimasi *VertiPaq Engine*, lengkap dengan contoh teknis.

---

# 📘 SOP: SSAS & Power BI Premium Performance Tuning Guide

**Tujuan:** Memastikan model tabular SSAS memiliki waktu pemrosesan (*refresh time*) yang cepat, konsumsi memori (RAM) yang efisien, dan waktu respon *query* (DAX) yang optimal.

## Fase 1: Partitioning & Refresh Strategy (Prioritas Utama - Dampak 70-80%)

**Prinsip:** Jangan pernah melakukan proses *full scan* pada data yang tidak berubah.

1. **Terapkan *Sliding Window Partitioning* pada Fact Table berukuran besar.**
* Pisahkan data aktif (sering berubah/bertambah) dan data historis (statis) ke dalam partisi yang berbeda.
* *Contoh:*
* Partisi Tahunan untuk historis statis: `FactSales_2024`, `FactSales_2025`
* Partisi Bulanan/Harian untuk data aktif: `FactSales_2026_08`, `FactSales_2026_09` (Bulan Berjalan).




2. **Gunakan *Incremental Refresh* berdasarkan tipe partisi.**
* Gunakan `ProcessFull` atau `ProcessAdd` **hanya** pada partisi aktif (misal: bulan berjalan atau hari ini).
* Hindari menggunakan `ProcessFull` pada partisi historis (misal: data tahun lalu) kecuali terjadi perubahan skema tabel atau perbaikan data masal.


3. **Lakukan pre-agregasi di layer SQL/Staging.**
* Jika *report* hanya membutuhkan data level harian, jangan tarik data berbutir jam/menit/detik ke SSAS. Lakukan `GROUP BY` di *Data Warehouse* terlebih dahulu.



## Fase 2: Model Design & Table Schema

**Prinsip:** Model data harus ramping dan hanya membawa data yang benar-benar dianalisis.

1. **Terapkan *Star Schema* secara ketat.**
* Hindari *Snowflake schema* (dimensi yang berelasi dengan dimensi lain) karena membebani memori saat *join*. Lakukan denormalisasi dimensi di level SQL.


2. **Gunakan *Single-Directional Relationship* sebagai standar baku.**
* Hindari *Bi-directional filtering* (Cross-filter direction: Both) di level model karena memicu ambiguitas dan melambatkan evaluasi DAX.
* *Contoh Solusi:* Jika sesekali butuh filter dua arah, gunakan fungsi `CROSSFILTER(Table1[Col], Table2[Col], BOTH)` di dalam *Measure* tertentu, bukan di *Relationship* model.


3. **Pisahkan kolom Date dan Time (Split Date/Time).**
* Tipe data `DateTime` hingga level detik memiliki kardinalitas sangat tinggi dan tidak bisa dikompresi oleh VertiPaq.
* *Contoh:* Pisahkan `TransactionTime (2026-09-08 14:30:15)` menjadi dua kolom integer: `DateKey (20260908)` dan `TimeKey (1430)`.


4. **Impor hanya kolom yang dibutuhkan secara analitik (Hindari `SELECT *`).**
* Hapus kolom operasional sistem yang tidak pernah dipakai di visualisasi laporan (contoh: `CreatedBy`, `ModifiedDate`, `SystemETLFlag`).



## Fase 3: Source Query, Data Types & Encoding

**Prinsip:** Bantu *engine* mengompresi data dengan memberikan tipe data teringan dan struktur pemrosesan terbersih.

1. **Gunakan tipe data *Currency/Fixed Decimal* untuk Nilai Uang.**
* Jangan gunakan tipe `Decimal/Float` untuk harga atau nominal uang. *VertiPaq Engine* mengompresi tipe `Currency` seefisien `Integer`, sedangkan `Float` memakan memori CPU yang sangat besar.


2. **Eliminasi kolom *High-Cardinality* (Zero-Value Columns).**
* Semakin banyak nilai unik dalam satu kolom, semakin besar ukuran *dictionary*-nya di RAM.
* *Contoh:* Hapus kolom *Primary Key* transaksi seperti GUID (`a8b9c...-123x...`), nomor resi, atau teks *Notes/Comments* panjang jika tidak digunakan untuk filter/agregasi.


3. **Pindahkan logika kompleks dari *Query Partition* ke SQL View (Materialization).**
* Jangan menulis CTE kompleks, `UNION ALL`, atau perhitungan string/tanggal (*on-the-fly*) di dalam *query partition* SSAS.
* *Contoh:* Buat `Indexed View` atau `Materialized Table` di SQL Server (`CREATE VIEW v_FactSales AS ...`), lalu jadikan `SELECT * FROM v_FactSales` sebagai *source query* di SSAS. Ini memaksimalkan kecepatan I/O.



## Fase 4: Calculated Columns & DAX Design

**Prinsip:** Geser komputasi statis ke kiri (ke SQL), lakukan komputasi dinamis di kanan (Measure).

1. **Terapkan Aturan "Shift-Left" untuk *Calculated Columns*.**
* *Calculated Column* (terutama di *Fact Table*) memakan RAM utuh dan tidak terkompresi sebaik kolom bawaan dari sumber. Pindahkan logika IF bercabang, penggabungan teks (*concatenation*), dan ekstraksi tanggal ke *SQL View* atau *ETL Pipeline*.
* *Contoh:* Daripada membuat calculated column `YearMonth = YEAR([Date]) & "-" & MONTH([Date])` di SSAS, buat kolom ini di tabel/view Dimensi Waktu di database.


2. **Gantikan *Calculated Column* dengan *Measure* jika memungkinkan.**
* *Measure* dihitung secara *on-the-fly* pada saat *query* menggunakan CPU, sehingga menghemat kapasitas RAM secara masif.
* *Contoh:* Daripada membuat *calculated column* `Profit = Fact[Sales] - Fact[Cost]`, lebih baik gunakan *Measure* `Total Profit = SUM(Fact[Sales]) - SUM(Fact[Cost])`.


3. **Hindari Anti-Pattern DAX (seperti FILTER(ALL)).**
* Hindari menggunakan `FILTER(ALL(Table))` jika Anda hanya ingin memfilter satu kolom tertentu.
* *Contoh:*
* **Buruk:** `CALCULATE(SUM(Sales), FILTER(ALL(Customer), Customer[Country] = "ID"))` (me-scan seluruh tabel).
* **Baik:** `CALCULATE(SUM(Sales), KEEPFILTERS(Customer[Country] = "ID"))` (jauh lebih cepat dan hemat memori).





## Fase 5: Pengukuran & Profiling (Wajib Dilakukan)

**Prinsip:** Jangan menebak bottleneck, ukurlah menggunakan alat yang tepat.

1. **Gunakan VertiPaq Analyzer (via DAX Studio atau Tabular Editor).**
* **Tindakan:** Jalankan VertiPaq Analyzer pada model yang sudah di-*process*. Sortir berdasarkan **Dictionary Size** dan **Data Size**.
* **Target:** Temukan Top 5 kolom yang paling memakan RAM. Evaluasi apakah kolom tersebut benar-benar dibutuhkan atau bisa diturunkan kardinalitasnya (Fase 3).


2. **Analisis *Server Timings* dengan DAX Studio.**
* **Tindakan:** Saat ada report yang lambat, copy DAX *query*-nya ke DAX Studio dan nyalakan *Server Timings*.
* **Target:** Pastikan rasio *Storage Engine* lebih dominan (bekerja efisien) daripada *Formula Engine*. Jika *Formula Engine* bekerja keras, perbaiki struktur DAX atau sederhanakan hubungan skema model.