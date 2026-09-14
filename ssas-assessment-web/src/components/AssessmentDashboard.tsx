"use client";

import { useEffect, useMemo, useState } from "react";
import ApexChart from "./ApexChart";
import type { ApexOptions } from "apexcharts";
import type { Candidate, ReportData } from "@/types/report";
import Link from "next/link";

const STORAGE_KEY = "ssas-assessment-custom-v5";
const sectionLabels: Record<string, string> = {
  overview: "Ringkasan eksekutif",
  coverage: "Cakupan evidence",
  charts: "Analisis visual",
  candidates: "Kandidat deep dive",
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
      <div className="signals"><p className="eyebrow">Sinyal lintas evidence</p><ul>{item.signals.map((signal) => <li key={signal}>{signal}</li>)}</ul></div>
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

  return (
    <main>
      <aside className="rail no-print">
        <a className="brand" href="#top"><span>SA</span><b>SSAS<br/>Assessment</b></a>
        <nav>
          {Object.entries(sectionLabels).map(([id, label]) => report.visibleSections[id] && <a href={`#${id}`} key={id}>{label}</a>)}
          <a href="#timeline">Timeline tuning</a>
          <Link href="/fleet">Daftar seluruh model →</Link>
          <Link href="/findings">Dokumen findings →</Link>
          <Link href="/glossary">Glosarium →</Link>
          <Link href="/scoring">Simulator scoring →</Link>
        </nav>
        <div className="rail-foot"><span className="live-dot"/> Evidence tersedia</div>
      </aside>

      <div className="report-shell" id="top">
        <header className="hero print-page">
          <div className="hero-copy"><h1>{report.meta.title}</h1><p className="dek">{report.meta.subtitle}</p></div>
          <div className="hero-meta"><div><span>Evidence set</span><b>{report.meta.evidenceSet}</b></div><div><span>Tanggal assessment</span><b>{report.meta.assessmentDate}</b></div><div><span>Klasifikasi</span><b>{report.meta.confidentiality}</b></div></div>
        </header>

        {report.visibleSections.overview && <section id="overview" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">01 · Ringkasan eksekutif</p><h2>Prioritas struktural, bukan kesimpulan performa.</h2></div><p className="section-note">Static score memandu urutan investigasi. Root cause tetap memerlukan workload dan processing evidence yang comparable.</p></div>
          <div className="metric-grid">
            <Metric label="Risiko fleet" value={`${report.summary.fleetScore}/100`} note={`${report.summary.fleetRisk} · static score relatif terhadap fleet`} tone="orange" />
            <Metric label="Model yang dinilai" value={`${report.summary.tabularDatabases + report.summary.multidimensionalDatabases}`} note={`${report.summary.tabularDatabases} Tabular · ${report.summary.multidimensionalDatabases} Multidimensional`} />
            <Metric label="Query bisnis terekam" value={formatNumber(report.summary.capturedBusinessQueries)} note="Query Tabular terekam · representativitas belum terbukti" tone="blue" />
            <Metric label="Kandidat deep dive" value={String(report.candidates.length)} note="Batas maksimum kandidat untuk tuning terkontrol" tone="ink" />
          </div>
          <div className="callout"><b>Batas evidence saat ini</b><span>Durasi refresh, processing bottleneck, peak concurrency, capacity pressure, dan root cause akhir <strong>NOT PROVABLE FROM CURRENT EVIDENCE</strong>.</span></div>
        </section>}

        {report.visibleSections.coverage && <section id="coverage" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">02 · Cakupan evidence</p><h2>Evidence yang tersedia, parsial, dan belum tersedia.</h2></div></div>
          <div className="coverage-list">{report.coverage.map((item) => <article key={item.area}><span className={`status status-${item.status.toLowerCase()}`}>{item.status}</span><div><h3>{item.area}</h3><p>{item.note}</p></div></article>)}</div>
        </section>}

        {report.visibleSections.charts && <section id="charts" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">03 · Analisis visual</p><h2>Paparan risiko dan distribusi prioritas.</h2></div></div>
          <div className="chart-grid">
            <article className="chart-card chart-wide"><div><h3>Static risk score</h3><p>Diurutkan dari static score tertinggi; berbeda dari urutan gabungan kandidat deep dive.</p></div><ApexChart type="bar" series={[{ name: "Score", data: scoreCandidates.map((c) => c.score) }]} options={scoreOptions} height={365}/></article>
            <article className="chart-card chart-wide"><div><h3>Distribusi prioritas model</h3><p>Jumlah seluruh model dalam fleet berdasarkan prioritas P0-P3; prioritas adalah alat triase relatif, bukan bukti defect.</p></div><ApexChart type="bar" series={[{ name: "Jumlah model", data: priorityCounts }]} options={priorityOptions} height={315}/></article>
          </div>
        </section>}

        {report.visibleSections.candidates && <section id="candidates" className="section">
          <div className="section-title print-page"><div><p className="eyebrow">05 · Kandidat deep dive</p><h2>Delapan jalur investigasi prioritas.</h2></div><p className="section-note">Kandidat dipilih dari kombinasi sinyal static dan runtime, lalu ditampilkan berdasarkan static score tertinggi. P0-P3 berasal dari static score dan bukan bukti defect.</p></div>
          <div className="candidate-list">{scoreCandidates.map((item, index) => <CandidateCard item={item} displayRank={index + 1} key={item.database}/>)}</div>
        </section>}

        {report.visibleSections.multidimensional && <section id="multidimensional" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">06 · Multidimensional</p><h2>Scoring terpisah dengan batas interpretasi yang jelas.</h2></div></div>
          <div className="md-grid">{report.multidimensional.map((item) => <article key={item.database}><div className="md-title"><h3>{item.database}</h3><span className={`badge risk-${item.risk.toLowerCase()}`}>{item.risk}/{item.priority}</span></div><strong>{item.score}<small>/100</small></strong><dl><div><dt>Partisi</dt><dd>{item.partitions}</dd></div><div><dt>Atribut</dt><dd>{item.attributes}</dd></div><div><dt>Query XEvent</dt><dd>{item.capturedQueries}</dd></div><div><dt>MDX bisnis</dt><dd>{item.businessQueries}</dd></div></dl><p>Cakupan runtime: <b>{item.runtimeCoverage}</b>. Durasi yang terekam berasal dari metadata discovery, bukan latency pengguna.</p></article>)}</div>
        </section>}

        <section id="timeline" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">Timeline tuning</p><h2>Rencana kerja DTSX dan model SSAS selama 20 mandays.</h2></div><p className="section-note">Estimasi berurutan untuk satu workstream. Jadwal aktual mengikuti kesiapan akses, owner, test environment, approval, dan change window.</p></div>
          <div className="timeline-frame"><img src="/timeline-tuning-dtsx-ssas-20md.svg" alt="Gantt timeline 20 mandays untuk tuning DTSX dan model SSAS"/></div>
          <p className="table-footnote">Tuning belum dianggap berhasil sebelum semantic regression test, benchmark before/after, SIT/UAT, dan rollback gate selesai. Aktivitas production tidak termasuk tanpa approval dan change window.</p>
        </section>

        <footer><span>{report.meta.evidenceSet}</span><span>Dihasilkan dari data report lokal yang dapat diedit</span></footer>
      </div>

      <div className="float-actions no-print">
        <button className="float-btn secondary" onClick={() => { setJsonDraft(JSON.stringify(report, null, 2)); setCustomizeOpen(true); }} aria-label="Sesuaikan report"><EditIcon/><span>Sesuaikan</span></button>
        <button className="float-btn primary" onClick={() => window.print()} aria-label="Ekspor PDF A4"><PrintIcon/><span>Ekspor PDF · A4</span></button>
      </div>

      {customizeOpen && <div className="drawer-backdrop no-print" onMouseDown={(e) => e.currentTarget === e.target && setCustomizeOpen(false)}>
        <aside className="drawer">
          <div className="drawer-head"><div><p className="eyebrow">Kontrol report</p><h2>Sesuaikan assessment</h2></div><button onClick={() => setCustomizeOpen(false)} aria-label="Tutup">×</button></div>
          <div className="drawer-body">
            <div className="control-group"><label>Judul report<input value={report.meta.title} onChange={(e) => setReport({ ...report, meta: { ...report.meta, title: e.target.value } })}/></label><label>Subjudul<textarea rows={2} value={report.meta.subtitle} onChange={(e) => setReport({ ...report, meta: { ...report.meta, subtitle: e.target.value } })}/></label></div>
            <div className="control-group"><h3>Section yang ditampilkan</h3>{Object.entries(sectionLabels).map(([id,label]) => <label className="switch-row" key={id}><span>{label}</span><input type="checkbox" checked={Boolean(report.visibleSections[id])} onChange={() => toggleSection(id)}/></label>)}</div>
            <div className="control-group"><div className="json-title"><div><h3>Edit seluruh JSON report</h3><p>Tambahkan atau hapus kandidat dan baris coverage.</p></div></div><textarea className="json-editor" spellCheck={false} value={jsonDraft} onChange={(e) => setJsonDraft(e.target.value)}/>{jsonError && <p className="json-error">{jsonError}</p>}</div>
          </div>
          <div className="drawer-actions"><button onClick={reset}>Kembalikan default</button><button className="apply" onClick={applyJson}>Terapkan JSON</button></div>
        </aside>
      </div>}
    </main>
  );
}

function PrintIcon() { return <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 8V3h10v5M7 17H5a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2M7 14h10v7H7z"/></svg>; }
function EditIcon() { return <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 20h9M16.5 3.5a2.12 2.12 0 0 1 3 3L8 18l-4 1 1-4z"/></svg>; }
