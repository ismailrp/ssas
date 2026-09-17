"use client";

import { useEffect, useMemo, useState } from "react";
import ApexChart from "./ApexChart";
import type { ApexOptions } from "apexcharts";
import type { Candidate, ReportData } from "@/types/report";
import Link from "next/link";

const STORAGE_KEY = "ssas-assessment-custom-v9";
const sectionLabels: Record<string, string> = {
  overview: "Executive summary",
  coverage: "Evidence coverage",
  methodology: "Metode perhitungan score",
  charts: "Analisis visual",
  candidates: "Model prioritas",
  multidimensional: "Multidimensional",
};

const riskColor: Record<string, string> = {
  CRITICAL: "#db4b4b",
  HIGH: "#ef8f36",
  MEDIUM: "#d9a928",
  LOW: "#2b9c78",
};

const formatNumber = (value: number) => new Intl.NumberFormat("id-ID").format(value);
const formatMs = (value: number | null) => (value === null ? "Belum tersedia" : `${formatNumber(value)} ms`);
const normalizeReport = (data: ReportData): ReportData => ({
  ...data,
  runtimeBaseline: data.runtimeBaseline ?? [],
  candidates: [...data.candidates]
    .sort((a, b) => b.score - a.score || a.database.localeCompare(b.database))
    .map((candidate, index) => ({ ...candidate, rank: index + 1 })),
});

function Metric({ label, value, note, tone = "teal" }: { label: string; value: string; note: string; tone?: string }) {
  return (
    <article className={`metric metric-${tone}`}>
      <p>{label}</p><strong>{value}</strong><span>{note}</span>
    </article>
  );
}

function CandidateCard({ item, displayRank }: { item: Candidate; displayRank: number }) {
  return (
    <article className="candidate-card print-avoid">
      <div className="candidate-head">
        <span className="rank">{String(displayRank).padStart(2, "0")}</span>
        <div><p className="eyebrow">{item.status}</p><h3>{item.database}</h3></div>
        <div className="score-ring" style={{ "--score-color": riskColor[item.risk] } as React.CSSProperties}>
          <strong>{item.score}</strong><small>/100</small>
        </div>
      </div>
      <div className="badge-row">
        <span className={`badge risk-${item.risk.toLowerCase()}`}>{item.risk} / {item.priority}</span>
        {item.classifications.map((value) => <span className="badge neutral" key={value}>{value}</span>)}
      </div>
      <div className="candidate-grid">
        <div><span>Runtime</span><strong>{item.runtimeExecutions ? `${formatNumber(item.runtimeExecutions)} eksekusi` : "Belum terekam"}</strong></div>
        <div><span>Total durasi terekam</span><strong>{item.runtimeExecutions ? formatMs(item.runtimeTotalMs) : "NOT PROVABLE"}</strong></div>
        <div><span>P95 / maksimum</span><strong>{item.runtimeP95Ms === null ? "Belum tersedia" : `${formatMs(item.runtimeP95Ms)} / ${formatMs(item.runtimeMaxMs)}`}</strong></div>
        <div><span>Model</span><strong>{item.tables} tabel · {item.columns} kolom · {item.measures} measure</strong></div>
      </div>
      <div className="signals"><p className="eyebrow">Sinyal dari berbagai evidence</p><ul>{item.signals.map((signal) => <li key={signal}>{signal}</li>)}</ul></div>
      <div className="action-box"><p><b>Tindakan.</b> {item.action}</p><p><b>Validasi.</b> {item.validation}</p></div>
    </article>
  );
}

export default function AssessmentDashboard({ initialData }: { initialData: ReportData }) {
  const normalizedInitial = useMemo(() => normalizeReport(initialData), [initialData]);
  const [report, setReport] = useState(normalizedInitial);
  const [customizeOpen, setCustomizeOpen] = useState(false);
  const [jsonDraft, setJsonDraft] = useState(JSON.stringify(normalizedInitial, null, 2));
  const [jsonError, setJsonError] = useState("");
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      try { const parsed = normalizeReport(JSON.parse(saved) as ReportData); setReport(parsed); setJsonDraft(JSON.stringify(parsed, null, 2)); } catch { localStorage.removeItem(STORAGE_KEY); }
    }
    setReady(true);
  }, []);

  useEffect(() => { if (ready) localStorage.setItem(STORAGE_KEY, JSON.stringify(report)); }, [report, ready]);

  const scoreCandidates = useMemo(
    () => [...report.candidates].sort((a, b) => b.score - a.score || a.database.localeCompare(b.database)),
    [report.candidates],
  );
  const scoreOptions: ApexOptions = useMemo(() => ({
    chart: { toolbar: { show: false }, animations: { enabled: false }, fontFamily: "var(--font-body)" },
    colors: scoreCandidates.map((c) => riskColor[c.risk]),
    plotOptions: { bar: { horizontal: true, distributed: true, borderRadius: 5, barHeight: "62%" } },
    dataLabels: { enabled: true, formatter: (v) => `${v}` },
    xaxis: { categories: scoreCandidates.map((c) => c.database), max: 100, labels: { style: { colors: "#65716d" } } },
    yaxis: { labels: { maxWidth: 190, style: { colors: "#24312d", fontSize: "12px", fontWeight: 600 } } },
    grid: { borderColor: "#e5eae7", strokeDashArray: 4 }, legend: { show: false }, tooltip: { y: { formatter: (v) => `${v}/100` } },
  }), [scoreCandidates]);

  const topRuntime = useMemo(
    () => [...report.runtimeBaseline].sort((a, b) => b.totalDurationMs - a.totalDurationMs || a.database.localeCompare(b.database)),
    [report.runtimeBaseline],
  );
  const runtimeOptions: ApexOptions = useMemo(() => ({
    chart: { toolbar: { show: false }, animations: { enabled: false }, fontFamily: "var(--font-body)" },
    colors: ["#287f9b"],
    plotOptions: { bar: { horizontal: true, borderRadius: 5, barHeight: "62%" } },
    dataLabels: { enabled: true, formatter: (value) => `${formatNumber(Number(value))} ms` },
    xaxis: { categories: topRuntime.map((item) => item.database), labels: { formatter: (value) => formatNumber(Number(value)), style: { colors: "#65716d" } }, title: { text: "Total durasi terekam (ms)" } },
    yaxis: { labels: { maxWidth: 210, style: { colors: "#24312d", fontSize: "12px", fontWeight: 600 } } },
    grid: { borderColor: "#e5eae7", strokeDashArray: 4 },
    legend: { show: false },
    tooltip: { y: { formatter: (value, context) => { const item = topRuntime[context?.dataPointIndex ?? 0]; return `${formatNumber(value)} ms total · ${formatNumber(item.executions)} eksekusi · P95 ${formatNumber(item.p95DurationMs)} ms`; } } },
  }), [topRuntime]);

  const priorityLevels = ["P0", "P1", "P2", "P3"] as const;
  const priorityCounts = useMemo(
    () => priorityLevels.map((priority) => report.fleet.filter((item) => item.priority === priority).length),
    [report.fleet],
  );
  const priorityOptions: ApexOptions = useMemo(() => ({
    chart: { toolbar: { show: false }, animations: { enabled: false }, fontFamily: "var(--font-body)" },
    colors: ["#db4b4b", "#ef8f36", "#d9a928", "#2b9c78"],
    plotOptions: { bar: { distributed: true, borderRadius: 5, columnWidth: "52%" } },
    dataLabels: { enabled: true, formatter: (value) => `${value} model` },
    xaxis: { categories: [...priorityLevels], labels: { style: { colors: "#24312d", fontSize: "12px", fontWeight: 700 } } },
    yaxis: { min: 0, forceNiceScale: true, labels: { formatter: (value) => `${Math.round(value)}` } },
    grid: { borderColor: "#e5eae7", strokeDashArray: 4 },
    legend: { show: false },
    tooltip: { y: { formatter: (value) => `${value} model dari ${report.fleet.length} model yang dinilai` } },
  }), [report.fleet.length]);

  const toggleSection = (id: string) => setReport((current) => ({ ...current, visibleSections: { ...current.visibleSections, [id]: !current.visibleSections[id] } }));
  const applyJson = () => {
    try { const parsed = normalizeReport(JSON.parse(jsonDraft) as ReportData); setReport(parsed); setJsonDraft(JSON.stringify(parsed, null, 2)); setJsonError(""); setCustomizeOpen(false); }
    catch (error) { setJsonError(error instanceof Error ? error.message : "JSON tidak valid"); }
  };
  const reset = () => { setReport(normalizedInitial); setJsonDraft(JSON.stringify(normalizedInitial, null, 2)); localStorage.removeItem(STORAGE_KEY); setJsonError(""); };
  const printReport = () => {
    window.dispatchEvent(new Event("resize"));
    window.setTimeout(() => window.print(), 250);
  };

  return (
    <main>
      <aside className="rail no-print">
        <a className="brand" href="#top"><span>SA</span><b>SSAS<br/>Assessment</b></a>
        <nav>
          {Object.entries(sectionLabels).map(([id, label]) => report.visibleSections[id] && <a href={`#${id}`} key={id}>{label}</a>)}
          <a href="#timeline">Timeline tuning</a>
          <Link href="/fleet">Daftar seluruh model →</Link>
          <Link href="/findings">Dokumen temuan →</Link>
          <Link href="/glossary">Glosarium →</Link>
          <Link href="/scoring">Simulator score →</Link>
        </nav>
        <div className="rail-foot"><span className="live-dot"/> Evidence tersedia</div>
      </aside>

      <div className="report-shell" id="top">
        <header className="hero print-page">
          <div className="hero-copy"><h1>{report.meta.title}</h1><p className="dek">{report.meta.subtitle}</p></div>
          <div className="hero-meta"><div><span>Evidence set</span><b>{report.meta.evidenceSet}</b></div><div><span>Tanggal assessment</span><b>{report.meta.assessmentDate}</b></div><div><span>Klasifikasi</span><b>{report.meta.confidentiality}</b></div></div>
        </header>

        {report.visibleSections.overview && <section id="overview" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">01 · Executive summary</p><h2>Hasil assessment ini sudah dapat digunakan untuk menentukan prioritas peningkatan performa.</h2></div><p className="section-note">Static score memberikan dasar yang terukur untuk memilih model dan area yang perlu ditindaklanjuti lebih dahulu, mencakup kompleksitas model, storage, partition, relationship, dan pola DAX. Tahap berikutnya dapat difokuskan pada validasi penyebab utama menggunakan workload yang representatif dan data processing dalam kondisi yang sebanding.</p></div>
          <div className="metric-grid">
            <Metric label="Risiko seluruh model" value={`${report.summary.fleetScore}/100`} note={`${report.summary.fleetRisk} · static score relatif terhadap seluruh model`} tone="orange" />
            <Metric label="Model yang dinilai" value={`${report.summary.tabularDatabases + report.summary.multidimensionalDatabases}`} note={`${report.summary.tabularDatabases} Tabular · ${report.summary.multidimensionalDatabases} Multidimensional`} />
            <Metric label="Query bisnis terekam" value={formatNumber(report.summary.capturedBusinessQueries)} note="Query Tabular terekam · representativitas belum terbukti" tone="blue" />
            <Metric label="Model prioritas" value={String(report.candidates.length)} note="Model dengan gabungan sinyal paling kuat untuk ditindaklanjuti" tone="ink" />
          </div>
          <div className="callout"><b>Batas evidence saat ini</b><span>Durasi refresh, bottleneck saat processing, peak concurrency, capacity pressure, dan root cause akhir <strong>NOT PROVABLE FROM CURRENT EVIDENCE</strong>.</span></div>
        </section>}

        {report.visibleSections.coverage && <section id="coverage" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">02 · Evidence coverage</p><h2>Evidence yang sudah lengkap, masih parsial, dan belum tersedia.</h2></div></div>
          <div className="coverage-list">{report.coverage.map((item) => <article key={item.area}><span className={`status status-${item.status.toLowerCase()}`}>{item.status}</span><div><h3>{item.area}</h3><p>{item.note}</p></div></article>)}</div>
        </section>}

        {report.visibleSections.methodology && <section id="methodology" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">03 · Metode perhitungan</p><h2>Score disusun dari lima aspek model yang dapat dibuktikan oleh evidence.</h2></div><p className="section-note">Setiap model dibandingkan dengan 54 model Tabular lainnya. Hasil akhirnya digunakan untuk menentukan prioritas relatif, bukan untuk menyatakan persentase kesehatan atau kecepatan model.</p></div>
          <div className="methodology-grid">
            <article><span>22,22%</span><h3>Complexity</h3><p>Jumlah tabel, kolom, measure, dan calculated column dibandingkan dengan seluruh model.</p></article>
            <article><span>27,78%</span><h3>Storage</h3><p>Posisi relatif USED_SIZE, dictionary size, dan jumlah baris terbesar.</p></article>
            <article><span>16,67%</span><h3>Partition</h3><p>Skala tabel dan pola partition, termasuk tabel besar dengan partition terbatas.</p></article>
            <article><span>16,67%</span><h3>Relationship</h3><p>Jumlah relationship serta indikator bidirectional dan many-to-many.</p></article>
            <article><span>16,67%</span><h3>Static DAX</h3><p>Frekuensi pola DAX yang layak diperiksa lebih lanjut; bukan bukti query lambat.</p></article>
          </div>
          <div className="score-formula"><div><p className="eyebrow">Formula per model</p><code>OverallScore = (Complexity × 22,22%) + (Storage × 27,78%) + (Partition × 16,67%) + (Relationship × 16,67%) + (Static DAX × 16,67%)</code></div><div><p className="eyebrow">Score lingkungan SSAS</p><strong>2.426 total score ÷ 54 model Tabular = 44,93 → 45/100</strong><p>Nilai 45 masuk kategori MEDIUM/P2 berdasarkan rentang prioritas yang digunakan assessment.</p></div></div>
          <div className="callout"><b>Mengapa runtime tidak dihitung?</b><span>Runtime baru terekam pada sebagian database dan representativitas workload belum terbukti. Agar score tetap adil dan dapat direproduksi, bobot runtime dikeluarkan lalu lima bobot yang memiliki evidence dinormalisasi menjadi 100%.</span></div>
          <p className="methodology-link"><Link href="/scoring">Buka simulator score untuk melihat contoh perhitungannya →</Link></p>
        </section>}

        {report.visibleSections.charts && <section id="charts" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">04 · Analisis visual</p><h2>Score risiko dan distribusi prioritas.</h2></div></div>
          <div className="chart-grid">
            <article className="chart-card chart-wide"><div><h3>Static risk score</h3><p>Diurutkan dari static score tertinggi. Urutan ini dapat berbeda dari daftar model prioritas yang menggunakan gabungan sinyal.</p></div><ApexChart type="bar" series={[{ name: "Score", data: scoreCandidates.map((c) => c.score) }]} options={scoreOptions} height={365}/></article>
            <article className="chart-card chart-wide"><div><h3>Top captured runtime</h3><p>Total durasi BUSINESS_CANDIDATE yang terekam per database. Nilai kumulatif dipengaruhi jumlah eksekusi dan representativitas workload belum terbukti; chart ini adalah sinyal prioritas, bukan perbandingan latency absolut.</p></div><ApexChart type="bar" series={[{ name: "Total durasi terekam", data: topRuntime.map((item) => item.totalDurationMs) }]} options={runtimeOptions} height={470}/></article>
            <article className="chart-card chart-wide"><div><h3>Distribusi prioritas model</h3><p>Jumlah model di seluruh lingkungan SSAS berdasarkan prioritas P0–P3. Prioritas digunakan untuk menentukan urutan tindak lanjut, bukan sebagai bukti adanya defect.</p></div><ApexChart type="bar" series={[{ name: "Jumlah model", data: priorityCounts }]} options={priorityOptions} height={315}/></article>
          </div>
        </section>}

        {report.visibleSections.candidates && <section id="candidates" className="section">
          <div className="section-title print-page"><div><p className="eyebrow">05 · Model prioritas</p><h2>Delapan model dengan prioritas tindak lanjut tertinggi.</h2></div><p className="section-note">Model dipilih dari kombinasi sinyal static dan runtime, lalu diurutkan berdasarkan static score. P0–P3 menunjukkan urutan penanganan, bukan bukti adanya defect.</p></div>
          <div className="candidate-list">{scoreCandidates.map((item, index) => <CandidateCard item={item} displayRank={index + 1} key={item.database}/>)}</div>
        </section>}

        {report.visibleSections.multidimensional && <section id="multidimensional" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">06 · Multidimensional</p><h2>Scoring terpisah untuk model multidimensional.</h2></div><p className="section-note">Setiap cube dibandingkan dengan fleet Multidimensional menggunakan kategori yang didukung evidence. Kategori yang tidak tersedia dikeluarkan dan bobot dinormalisasi.</p></div>
          <div className="methodology-grid">
            <article><span>01</span><h3>Structural</h3><p>Posisi relatif jumlah dimension attribute dan user-hierarchy level.</p></article>
            <article><span>02</span><h3>Partition</h3><p>Estimated rows terbesar dan konsentrasi rows, hanya ketika estimasi rows tersedia.</p></article>
            <article><span>03</span><h3>Relationship</h3><p>Measure-group dimension usage dan attribute relationship dibandingkan dalam fleet MD.</p></article>
            <article><span>04</span><h3>Aggregation</h3><p>Proporsi partition tanpa aggregation design; merupakan sinyal review, bukan otomatis defect.</p></article>
            <article><span>05</span><h3>Calculation</h3><p>Jumlah MDX calculation command secara relatif; jumlah command bukan bukti query lambat.</p></article>
          </div>
          <div className="callout"><b>Batas interpretasi</b><span>Score MD adalah prioritas investigasi relatif di antara dua cube, bukan ukuran latency atau kesehatan absolut. Runtime bisnis, aggregation hit rate, cache effectiveness, dan processing bottleneck masih <strong>NOT PROVABLE FROM CURRENT EVIDENCE</strong>.</span></div>
          <div className="md-grid">{report.multidimensional.map((item) => <article key={item.database}><div className="md-title"><h3>{item.database}</h3><span className={`badge risk-${item.risk.toLowerCase()}`}>{item.risk}/{item.priority}</span></div><strong>{item.score}<small>/100</small></strong><dl><div><dt>Partisi</dt><dd>{item.partitions}</dd></div><div><dt>Atribut</dt><dd>{item.attributes}</dd></div><div><dt>Query XEvent</dt><dd>{item.capturedQueries}</dd></div><div><dt>MDX bisnis</dt><dd>{item.businessQueries}</dd></div></dl><p>Cakupan runtime: <b>{item.runtimeCoverage}</b>. Durasi yang terekam berasal dari metadata discovery, bukan latency pengguna.</p></article>)}</div>
        </section>}

        <section id="timeline" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">07 · Timeline tuning</p><h2>Rencana tuning DTSX dan model SSAS selama 20 man-days.</h2></div><p className="section-note">Estimasi ini menggunakan satu workstream berurutan. Jadwal aktual menyesuaikan kesiapan akses, owner, test environment, approval, dan change window.</p></div>
          <div className="timeline-frame"><img src="/timeline-tuning-dtsx-ssas-20md.svg" alt="Gantt timeline 20 mandays untuk tuning DTSX dan model SSAS"/></div>
          <p className="table-footnote">Tuning baru dinyatakan berhasil setelah semantic regression test, benchmark before/after, SIT/UAT, dan rollback gate selesai. Aktivitas di production tidak termasuk tanpa approval dan change window.</p>
        </section>

        <footer><span>{report.meta.evidenceSet}</span><span>Dihasilkan dari data laporan lokal yang dapat diedit</span></footer>
      </div>

      <div className="float-actions no-print">
        <button className="float-btn secondary" onClick={() => { setJsonDraft(JSON.stringify(report, null, 2)); setCustomizeOpen(true); }} aria-label="Sesuaikan report"><EditIcon/><span>Sesuaikan</span></button>
        <button className="float-btn primary" onClick={printReport} aria-label="Ekspor PDF A4"><PrintIcon/><span>Ekspor PDF · A4</span></button>
      </div>

      {customizeOpen && <div className="drawer-backdrop no-print" onMouseDown={(e) => e.currentTarget === e.target && setCustomizeOpen(false)}>
        <aside className="drawer">
          <div className="drawer-head"><div><p className="eyebrow">Pengaturan laporan</p><h2>Sesuaikan assessment</h2></div><button onClick={() => setCustomizeOpen(false)} aria-label="Tutup">×</button></div>
          <div className="drawer-body">
            <div className="control-group"><label>Judul laporan<input value={report.meta.title} onChange={(e) => setReport({ ...report, meta: { ...report.meta, title: e.target.value } })}/></label><label>Subjudul<textarea rows={2} value={report.meta.subtitle} onChange={(e) => setReport({ ...report, meta: { ...report.meta, subtitle: e.target.value } })}/></label></div>
            <div className="control-group"><h3>Bagian yang ditampilkan</h3>{Object.entries(sectionLabels).map(([id,label]) => <label className="switch-row" key={id}><span>{label}</span><input type="checkbox" checked={Boolean(report.visibleSections[id])} onChange={() => toggleSection(id)}/></label>)}</div>
            <div className="control-group"><div className="json-title"><div><h3>Edit seluruh JSON laporan</h3><p>Tambahkan atau hapus kandidat dan baris coverage.</p></div></div><textarea className="json-editor" spellCheck={false} value={jsonDraft} onChange={(e) => setJsonDraft(e.target.value)}/>{jsonError && <p className="json-error">{jsonError}</p>}</div>
          </div>
          <div className="drawer-actions"><button onClick={reset}>Kembalikan default</button><button className="apply" onClick={applyJson}>Terapkan JSON</button></div>
        </aside>
      </div>}
    </main>
  );
}

function PrintIcon() { return <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 8V3h10v5M7 17H5a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2M7 14h10v7H7z"/></svg>; }
function EditIcon() { return <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 20h9M16.5 3.5a2.12 2.12 0 0 1 3 3L8 18l-4 1 1-4z"/></svg>; }
