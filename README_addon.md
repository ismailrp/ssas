# SSAS Runtime Evidence Add-on v0.1.0

Tambahan untuk toolkit SSAS assessment. Add-on ini menutup gap runtime evidence yang sebelumnya belum tersedia:
- XEvent QueryBegin / QueryEnd / ResourceUsage
- P50 / P95 / P99 dari QueryEnd
- kandidat query representatif QRY-001..QRY-005
- input manual DAX Studio Server Timings (FE/SE) per query
- evidence terstruktur untuk report/AI agent

## Prinsip
1. FE/SE adalah evidence **per query**, bukan nilai langsung per database.
2. P50/P95/P99 dihitung dari kumpulan QueryEnd dan harus diberi label sesuai sumber workload:
   - CONTROLLED: Excel/DAX Studio benchmark
   - PRODUCTION: workload user nyata
3. FE/SE tidak boleh diklaim sebagai karakteristik database jika hanya berasal dari satu query.
4. Query Plan bersifat optional deep-dive; assessment standar berhenti di runtime percentile + FE/SE.
5. QRY-001..QRY-005 tidak boleh ditebak/copy antar database. Kandidat dipilih dari workload database tersebut.

## Workflow praktis

### A. Capture XEvent
1. Edit `xmla/01_create_runtime_xevent.xmla`:
   - ganti `__SESSION_NAME__`
   - ganti `__XEL_PATH__`
2. Jalankan di SSMS -> Analysis Services -> New Query -> XMLA.
3. Jalankan workload Excel / DAX Studio / workload nyata.
4. Cek `$SYSTEM.DISCOVER_XEVENT_SESSION_TARGETS`.
5. Stop capture dengan menjalankan `xmla/02_delete_runtime_xevent.xmla`.
   Pada SSAS, delete Trace menghentikan session; file XEL yang sudah ditulis tetap menjadi evidence.
6. Buka XEL di SSMS dan Export ke CSV.

### B. Normalize + pilih kandidat
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Analyze-SSASRuntimeEvidence.ps1 `
  -InputCsv .\input\ActualVsAnggaran_Runtime_20260904.csv `
  -OutputDir .\output\ProduksiTBS `
  -Database "Actual vs Anggaran" `
  -WorkloadType CONTROLLED *>&1 | Out-File error.txt
```
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\scripts\Analyze-SSASRuntimeEvidence.ps1 -InputCsv .\input\ProduksiTBS.csv -OutputDir .\output\ProduksiTBS -Database "Produksi TBS" -WorkloadType CONTROLLED
Output:
- `runtime_query_evidence.csv`
- `runtime_percentiles.csv`
- `benchmark_query_manifest.csv`
- `server_timings_input.csv`
- `runtime_report_fragment.md`

### C. DAX Studio
Untuk setiap QRY-001..QRY-005:
1. Replay query/candidate yang relevan di DAX Studio.
2. Server Timings ON.
3. Catat hanya:
   - Duration_ms
   - FE_pct
   - SE_pct
   - SE_Queries
4. Isi `server_timings_input.csv`.

### D. Build evidence report
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Build-SSASRuntimeReport.ps1 `
  -RuntimeDir .\output\ProduksiTBS
```

Output:
- `SERVER_TIMINGS_EVIDENCE.csv`
- `SSAS_RUNTIME_ASSESSMENT.md`

## Query candidate rules
- QRY-001 = slowest distinct query
- QRY-002 = most frequent distinct query
- QRY-003 = highest CPU distinct query (fallback: next slowest)
- QRY-004 = query dengan kompleksitas text tertinggi (measure/dimension proxy; fallback: next distinct)
- QRY-005 = distinct representative query berikutnya

Generator tidak mengarang DAX baru. Ia memilih query yang benar-benar terlihat di XEvent. Jika workload tidak cukup untuk 5 distinct query, manifest akan menyisakan kandidat kosong/kurang dan itu harus dilaporkan sebagai evidence gap.

## Integrasi ke toolkit utama
Direkomendasikan di bawah EvidenceSet:

```
04_RUNTIME/
  XEVENT/
    raw/
    normalized/
  SERVER_TIMINGS/
    server_timings_input.csv
    SERVER_TIMINGS_EVIDENCE.csv
  BENCHMARK/
    benchmark_query_manifest.csv
  REPORT/
    SSAS_RUNTIME_ASSESSMENT.md
```

Report utama membaca:
- static/model/storage evidence yang sudah ada
- `runtime_percentiles.csv`
- `benchmark_query_manifest.csv`
- `SERVER_TIMINGS_EVIDENCE.csv`
- `SSAS_RUNTIME_ASSESSMENT.md`

Tidak perlu Query Plan untuk report assessment standar.
