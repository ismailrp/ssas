• Pemeriksaan dan parsing selesai. Evidence EVSET-005_MD valid dan report sudah diperbarui.

Hasil utama:

- Extended metadata kedua model: COMPLETE.
- Cube Sparta LHA: static score 67, HIGH/P1.
- MultidimensionalProjectMR: static score 50, MEDIUM/P2.
- Score bersifat relatif terhadap dua model, bukan bukti latency.

XEvent:

- Tabular: 31.280 events, 3.966 correlated queries.
  - 3.066 system/DMV.
  - 900 BUSINESS_CANDIDATE.

- Multidimensional: 391 events, 118 correlated queries.
  - Seluruhnya metadata/schema discovery.
  - Tidak ada business MDX query.
  - Tidak ada processing events.

- Captured window: 9–13 September 2026.

Kualitas korelasi Tabular:

- 773 query matched dengan Storage Engine events.
- 114 memiliki jumlah SE duration melebihi total—FE/SE turunannya tidak authoritative.
- 3.079 query tidak mempunyai matching SE event.

Error summary:

- Tabular: 432 event unsupported/unrecognized dan 100 permission/authorization.
- Multidimensional: 11 distinct error hashes, masih perlu request-context review.
- Error belum diperlakukan sebagai model/cube defect.

Perubahan prioritas: LKK Per Divisi masuk delapan deep-dive candidate karena satu outlier 14.078 ms dari hanya dua
execution. Ini REQUIRES VALIDATION; Saldo Treasury tetap dalam runtime baseline tetapi keluar dari cutoff delapan
kandidat.

Output penting:

- XEvent summary (evidence/EVSET-005_MD/RUNTIME/XEL-20260913/summary.json)
- Parser manifest (evidence/EVSET-005_MD/RUNTIME/XEL-20260913/parser_manifest.csv)
- Multidimensional scorecard (REPORTS/12_MULTIDIMENSIONAL_SCORECARD.csv)
- Multidimensional assessment (REPORTS/13_MULTIDIMENSIONAL_ASSESSMENT.md)
- XEvent quality review (REPORTS/14_XEVENT_PARSE_QUALITY.md)
- Draft laporan yang sudah disinkronkan (REPORTS/11_DRAFT_LAPORAN_TEMUAN_DAN_RENCANA_AKSI_OPTIMASI_SSAS.md)
- Tabular runtime baseline (REPORTS/07_RUNTIME_DATABASE_BASELINE.csv)

Parser juga sudah diperbarui agar otomatis menghasilkan error_summary.csv tanpa menyalin raw error/query text. Ketiga
script terkait lolos parser PowerShell tanpa error. Raw events.csv dan queries.csv tetap harus dianggap sensitif
karena memuat query text dan account metadata.

---

• Sudah dibuat delapan report DOCX editable, satu per deep-dive candidate:

1. LKK (REPORTS/SSAS_FINDING_DOCX/SSAS Finding-001-LKK.docx)
2. Segregation (REPORTS/SSAS_FINDING_DOCX/SSAS Finding-002-Segregation.docx)
3. LKK Per Divisi (REPORTS/SSAS_FINDING_DOCX/SSAS Finding-003-LKK Per Divisi.docx)
4. Premi Panen (REPORTS/SSAS_FINDING_DOCX/SSAS Finding-004-Premi Panen.docx)
5. Produksi TBS (REPORTS/SSAS_FINDING_DOCX/SSAS Finding-005-Produksi TBS.docx)
6. SPARTA_LHA_ENHC (REPORTS/SSAS_FINDING_DOCX/SSAS Finding-006-SPARTA_LHA_ENHC.docx)
7. premi dan lembur monitoring (REPORTS/SSAS_FINDING_DOCX/SSAS Finding-007-premi dan lembur monitoring.docx)
8. MRData (REPORTS/SSAS_FINDING_DOCX/SSAS Finding-008-MRData.docx)

Setiap dokumen memuat:

- Identitas database dan model profile.
- Static score, risk, dan priority.
- Captured runtime.
- Finding beserta OBSERVED, INFERRED, atau REQUIRES VALIDATION.
- Confidence, potential impact, dan evidence file.
- Action plan, expected benefit, effort, risk, dan validation.
- Implementation gate.
- Tabel before/after yang dapat diisi saat tuning.
- Ketentuan 3–5 query bisnis dan 2–3 refresh normal.

Tidak ada data, durasi, target, kategori masalah, atau nama package SSIS yang disalin. Template SSIS hanya digunakan
sebagai acuan style/container DOCX.

Generator reusable tersedia di generate_ssas_finding_docx.ps1, daftar output di REPORTS/SSAS_FINDING_DOCX/index.csv,
dan petunjuk regenerasi sudah ditambahkan ke notes/HOWTO_COLLECT_SSAS_EVIDENCE.md:287.

Seluruh DOCX lolos validasi struktur OpenXML, metadata template sudah diganti, dan tidak dibuat dalam format PDF.

---

• Web assessment sudah dibuat di folder baru ssas-assessment-web.

Fitur yang tersedia:

- Next.js 16.3.5 App Router, memenuhi permintaan versi 15+.
- Visualisasi ApexCharts:
  - Static risk score.
  - Captured runtime.
  - Evidence coverage.

- Delapan deep-dive candidate beserta action dan validation.
- Assessment Multidimensional terpisah.
- Implementation roadmap dan validation gate.
- Responsive untuk desktop, tablet, dan mobile.
- Floating button Export PDF · A4.
- Print stylesheet A4 dengan page-break protection untuk card, chart, dan tabel.
- Floating Customize:
  - Ubah judul/subjudul.
  - Tampilkan/sembunyikan section.
  - Edit seluruh JSON.
  - Tambah/hapus kandidat, roadmap, coverage, dan custom section.
  - Perubahan tersimpan di localStorage.
  - Reset ke data default.

File utama:

- Dashboard component (ssas-assessment-web/src/components/AssessmentDashboard.tsx)
- Assessment data (ssas-assessment-web/src/data/assessment.json)
- A4/Responsive CSS (ssas-assessment-web/src/app/globals.css)
- Petunjuk penggunaan (ssas-assessment-web/README.md)
- Package configuration (ssas-assessment-web/package.json)

Menjalankan aplikasi:

cd C:\Projects\sql\ssas\ssas-assessment-web
npm run dev

Buka:

http://localhost:3000

Tombol export membuka dialog cetak browser dengan konfigurasi A4. Pilih Save as PDF; layout navigasi dan tombol
otomatis disembunyikan.

Validasi selesai:

- npm install: 0 vulnerability.
- npm run build: berhasil.
- TypeScript: berhasil.
- Static prerender: berhasil.
- Smoke test HTTP: status 200.
- Next.js 16.3.5, React 19.3, ApexCharts 7.3.
- Production server berhasil dijalankan.

Implementasi mengikuti panduan App Router Next.js dan integrasi React resmi ApexCharts.

─ Worked for 10m 40s ───────────────────────────────────────────────────────────────────────────────────────────────────

─ Conversation recap ───────────────────────────────────────────────────────────────────────────────────────────────────

Web dokumentasi hasil assessment SSAS telah dibuat di folder root ssas-assessment-web menggunakan Next.js 16.3.5 App
Router dan ApexCharts. Tugas dinyatakan selesai; status pengujian belum disebutkan.

---

• Benar, sebelumnya 46 model lain tidak ditampilkan di web sehingga seolah-olah hilang. Itu kekurangan penyajian, bukan
kekurangan assessment.

Sudah ditambahkan bagian “Full fleet disposition” yang memuat seluruh 56 model:

- 8 DEEP_DIVE: investigasi awal.
- 5 WATCHLIST: score P1 tetapi belum masuk batas delapan kandidat.
- 41 MONITOR: tetap dalam fleet assessment dan dapat dinaikkan jika runtime/business impact mendukung.
- 2 MULTIDIMENSIONAL_REVIEW: memakai assessment terpisah.

Tabel menyediakan:

- Database dan model type.
- Static score dan risk.
- Prioritas P0–P3.
- Disposition.
- Jumlah table/column.
- Used MB.
- Runtime coverage.
- Pencarian dan filter disposition.

Data lengkap ada di ssas-assessment-web/src/data/fleet.json. Status MONITOR secara eksplisit tidak berarti model sehat
atau bebas finding—hanya belum menjadi delapan investigasi awal.

## Production build sudah berhasil dengan seluruh 56 model.

apa itu monitor business candidate,
partial business candidate,
disposition,
