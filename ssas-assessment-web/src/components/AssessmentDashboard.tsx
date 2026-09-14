"use client";

import { useEffect, useMemo, useState } from "react";
import ApexChart from "./ApexChart";
import type { ApexOptions } from "apexcharts";
import type { Candidate, ReportData } from "@/types/report";
import Link from "next/link";

const STORAGE_KEY = "ssas-assessment-custom-v3";
const sectionLabels: Record<string, string> = {
  overview: "Executive overview",
  coverage: "Evidence coverage",
  charts: "Visual analysis",
  fleet: "Full fleet disposition",
  candidates: "Deep-dive candidates",
  multidimensional: "Multidimensional",
  roadmap: "Implementation roadmap",
  validation: "Validation gate",
  custom: "Custom sections",
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
        <div><span>Runtime</span><strong>{item.runtimeExecutions ? `${formatNumber(item.runtimeExecutions)} executions` : "Belum tertangkap"}</strong></div>
        <div><span>Total captured</span><strong>{item.runtimeExecutions ? formatMs(item.runtimeTotalMs) : "NOT PROVABLE"}</strong></div>
        <div><span>P95 / max</span><strong>{item.runtimeP95Ms === null ? "Belum tersedia" : `${formatMs(item.runtimeP95Ms)} / ${formatMs(item.runtimeMaxMs)}`}</strong></div>
        <div><span>Model</span><strong>{item.tables} tables · {item.columns} columns · {item.measures} measures</strong></div>
      </div>
      <div className="signals"><p className="eyebrow">Cross-evidence signals</p><ul>{item.signals.map((signal) => <li key={signal}>{signal}</li>)}</ul></div>
      <div className="action-box"><p><b>Action.</b> {item.action}</p><p><b>Validation.</b> {item.validation}</p></div>
    </article>
  );
}

export default function AssessmentDashboard({ initialData }: { initialData: ReportData }) {
  const normalizedInitial = useMemo(() => normalizeReport(initialData), [initialData]);
  const [report, setReport] = useState(normalizedInitial);
  const [customizeOpen, setCustomizeOpen] = useState(false);
  const [jsonDraft, setJsonDraft] = useState(JSON.stringify(normalizedInitial, null, 2));
  const [jsonError, setJsonError] = useState("");
  const [fleetFilter, setFleetFilter] = useState("ALL");
  const [fleetSearch, setFleetSearch] = useState("");
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
  const runtimeCandidates = useMemo(
    () => [...report.candidates].sort((a, b) => b.runtimeTotalMs - a.runtimeTotalMs || b.score - a.score),
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

  const runtimeOptions: ApexOptions = useMemo(() => ({
    chart: { toolbar: { show: false }, animations: { enabled: false }, fontFamily: "var(--font-body)" },
    colors: ["#167d72"], plotOptions: { bar: { borderRadius: 5, columnWidth: "56%" } },
    dataLabels: { enabled: false },
    xaxis: { categories: runtimeCandidates.map((c) => c.database), labels: { rotate: -38, trim: true, style: { fontSize: "10px" } } },
    yaxis: { logarithmic: true, min: 1, labels: { formatter: (v) => formatNumber(Math.round(v)) } },
    grid: { borderColor: "#e5eae7", strokeDashArray: 4 }, tooltip: { y: { formatter: (v) => `${formatNumber(v)} ms captured total` } },
  }), [runtimeCandidates]);

  const coverageCounts = useMemo(() => {
    const statuses = ["COMPLETE", "PARTIAL", "MISSING", "UNSUPPORTED", "SKIPPED"];
    return statuses.map((status) => report.coverage.filter((item) => item.status === status).length);
  }, [report.coverage]);

  const dispositionCounts = useMemo(() => ({
    DEEP_DIVE: report.fleet.filter((item) => item.disposition === "DEEP_DIVE").length,
    WATCHLIST: report.fleet.filter((item) => item.disposition === "WATCHLIST").length,
    MONITOR: report.fleet.filter((item) => item.disposition === "MONITOR").length,
    MULTIDIMENSIONAL_REVIEW: report.fleet.filter((item) => item.disposition === "MULTIDIMENSIONAL_REVIEW").length,
  }), [report.fleet]);
  const visibleFleet = useMemo(() => report.fleet
    .filter((item) => fleetFilter === "ALL" || item.disposition === fleetFilter)
    .filter((item) => item.database.toLowerCase().includes(fleetSearch.trim().toLowerCase()))
    .sort((a, b) => (b.score ?? -1) - (a.score ?? -1) || a.database.localeCompare(b.database)),
  [report.fleet, fleetFilter, fleetSearch]);

  const coverageOptions: ApexOptions = useMemo(() => ({
    chart: { animations: { enabled: false }, fontFamily: "var(--font-body)" },
    labels: ["Complete", "Partial", "Missing", "Unsupported", "Skipped"], colors: ["#188773", "#e0a52a", "#d55656", "#7d6f9e", "#94a09b"],
    legend: { position: "bottom", fontSize: "11px" }, dataLabels: { enabled: true }, stroke: { width: 3, colors: ["#fff"] },
    plotOptions: { pie: { donut: { size: "68%", labels: { show: true, total: { show: true, label: "Coverage areas", formatter: () => `${report.coverage.length}` } } } } },
  }), [report.coverage.length]);

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
          <Link href="/glossary">Glossary →</Link>
          <Link href="/scoring">Scoring simulator →</Link>
        </nav>
        <div className="rail-foot"><span className="live-dot"/> Evidence loaded</div>
      </aside>

      <div className="report-shell" id="top">
        <header className="hero print-page">
          <div className="hero-copy"><p className="kicker">PERFORMANCE ENGINEERING · SEMANTIC MODELS</p><h1>{report.meta.title}</h1><p className="dek">{report.meta.subtitle}</p></div>
          <div className="hero-meta"><div><span>Evidence set</span><b>{report.meta.evidenceSet}</b></div><div><span>Assessment date</span><b>{report.meta.assessmentDate}</b></div><div><span>Classification</span><b>{report.meta.confidentiality}</b></div></div>
        </header>

        {report.visibleSections.overview && <section id="overview" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">01 · Executive overview</p><h2>Prioritas struktural, bukan vonis performa.</h2></div><p className="section-note">Static score memandu urutan investigasi. Root cause tetap membutuhkan workload dan processing evidence yang comparable.</p></div>
          <div className="metric-grid">
            <Metric label="Fleet risk" value={`${report.summary.fleetScore}/100`} note={`${report.summary.fleetRisk} · fleet-relative static score`} tone="orange" />
            <Metric label="Assessed models" value={`${report.summary.tabularDatabases + report.summary.multidimensionalDatabases}`} note={`${report.summary.tabularDatabases} Tabular · ${report.summary.multidimensionalDatabases} Multidimensional`} />
            <Metric label="Business candidates" value={formatNumber(report.summary.capturedBusinessQueries)} note="Captured Tabular queries · representativeness pending" tone="blue" />
            <Metric label="Deep dives" value={String(report.candidates.length)} note="Maximum candidate set for controlled tuning" tone="ink" />
          </div>
          <div className="callout"><b>Current evidence boundary</b><span>Refresh duration, processing bottleneck, peak concurrency, capacity pressure, and final causal root cause are <strong>NOT PROVABLE FROM CURRENT EVIDENCE</strong>.</span></div>
        </section>}

        {report.visibleSections.coverage && <section id="coverage" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">02 · Evidence coverage</p><h2>Yang tersedia, parsial, dan masih kosong.</h2></div></div>
          <div className="coverage-list">{report.coverage.map((item) => <article key={item.area}><span className={`status status-${item.status.toLowerCase()}`}>{item.status}</span><div><h3>{item.area}</h3><p>{item.note}</p></div></article>)}</div>
        </section>}

        {report.visibleSections.charts && <section id="charts" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">03 · Visual analysis</p><h2>Risk exposure dan captured runtime.</h2></div></div>
          <div className="chart-grid">
            <article className="chart-card chart-wide"><div><h3>Static risk score</h3><p>Diurutkan dari static score tertinggi; berbeda dari urutan deep-dive gabungan.</p></div><ApexChart type="bar" series={[{ name: "Score", data: scoreCandidates.map((c) => c.score) }]} options={scoreOptions} height={365}/></article>
            <article className="chart-card"><div><h3>Evidence coverage</h3><p>Status by assessment domain.</p></div><ApexChart type="donut" series={coverageCounts} options={coverageOptions} height={315}/></article>
            <article className="chart-card"><div><h3>Captured duration</h3><p>Diurutkan dari total captured duration tertinggi; log scale, bukan typical latency.</p></div><ApexChart type="bar" series={[{ name: "Total ms", data: runtimeCandidates.map((c) => Math.max(1, c.runtimeTotalMs)) }]} options={runtimeOptions} height={315}/></article>
          </div>
        </section>}

        {report.visibleSections.fleet && <section id="fleet" className="section">
          <div className="section-title print-page"><div><p className="eyebrow">04 · Full fleet disposition</p><h2>Seluruh 56 model tetap dalam assessment.</h2></div><p className="section-note">Deep dive adalah urutan investigasi awal, bukan satu-satunya model yang dinilai. Watchlist dan monitoring tetap dipertahankan sampai runtime atau business impact menaikkan prioritas.</p></div>
          <div className="disposition-grid print-avoid">
            <button className={fleetFilter === "ALL" ? "active" : ""} onClick={() => setFleetFilter("ALL")}><strong>{report.fleet.length}</strong><span>All assessed</span></button>
            <button className={fleetFilter === "DEEP_DIVE" ? "active" : ""} onClick={() => setFleetFilter("DEEP_DIVE")}><strong>{dispositionCounts.DEEP_DIVE}</strong><span>Deep dive</span></button>
            <button className={fleetFilter === "WATCHLIST" ? "active" : ""} onClick={() => setFleetFilter("WATCHLIST")}><strong>{dispositionCounts.WATCHLIST}</strong><span>P1 watchlist</span></button>
            <button className={fleetFilter === "MONITOR" ? "active" : ""} onClick={() => setFleetFilter("MONITOR")}><strong>{dispositionCounts.MONITOR}</strong><span>Fleet monitor</span></button>
            <button className={fleetFilter === "MULTIDIMENSIONAL_REVIEW" ? "active" : ""} onClick={() => setFleetFilter("MULTIDIMENSIONAL_REVIEW")}><strong>{dispositionCounts.MULTIDIMENSIONAL_REVIEW}</strong><span>MD review</span></button>
          </div>
          <div className="fleet-tools no-print"><input type="search" value={fleetSearch} onChange={(event) => setFleetSearch(event.target.value)} placeholder="Cari database..."/><span>Menampilkan {visibleFleet.length} model</span></div>
          <div className="fleet-table-wrap"><table className="fleet-table"><thead><tr><th>Database</th><th>Type</th><th>Score</th><th>Risk</th><th>Priority</th><th>Disposition</th><th>Tables</th><th>Columns</th><th>Used MB*</th><th>Runtime coverage</th></tr></thead><tbody>{visibleFleet.map((item) => <tr key={`${item.modelType}-${item.database}`}><td><b>{item.database}</b></td><td>{item.modelType === "MULTIDIMENSIONAL" ? "MD" : "Tabular"}</td><td>{item.score ?? "—"}</td><td><span className={`badge ${item.risk === "INFORMATIONAL" ? "neutral" : `risk-${item.risk.toLowerCase()}`}`}>{item.risk}</span></td><td>{item.priority}</td><td><span className={`disposition disposition-${item.disposition.toLowerCase()}`}>{item.disposition.replaceAll("_", " ")}</span></td><td>{item.tables}</td><td>{item.columns}</td><td>{item.usedMb || "—"}</td><td>{item.runtimeCoverage.replaceAll("_", " ")}</td></tr>)}</tbody></table></div>
          <p className="table-footnote">* DMV accounting untuk ranking relatif, bukan authoritative resident memory. MONITOR tidak berarti sehat atau bebas finding; artinya belum dipilih untuk delapan deep-dive awal.</p>
        </section>}

        {report.visibleSections.candidates && <section id="candidates" className="section">
          <div className="section-title print-page"><div><p className="eyebrow">05 · Deep-dive candidates</p><h2>Delapan investigation tracks.</h2></div><p className="section-note">Kandidat dipilih dari kombinasi static dan runtime signal, lalu ditampilkan berdasarkan static score tertinggi. P0-P3 hanya berasal dari static score dan bukan bukti defect.</p></div>
          <div className="candidate-list">{scoreCandidates.map((item, index) => <CandidateCard item={item} displayRank={index + 1} key={item.database}/>)}</div>
        </section>}

        {report.visibleSections.multidimensional && <section id="multidimensional" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">06 · Multidimensional</p><h2>Separate scoring, explicit limitations.</h2></div></div>
          <div className="md-grid">{report.multidimensional.map((item) => <article key={item.database}><div className="md-title"><h3>{item.database}</h3><span className={`badge risk-${item.risk.toLowerCase()}`}>{item.risk}/{item.priority}</span></div><strong>{item.score}<small>/100</small></strong><dl><div><dt>Partitions</dt><dd>{item.partitions}</dd></div><div><dt>Attributes</dt><dd>{item.attributes}</dd></div><div><dt>XEvent queries</dt><dd>{item.capturedQueries}</dd></div><div><dt>Business MDX</dt><dd>{item.businessQueries}</dd></div></dl><p>Runtime coverage: <b>{item.runtimeCoverage}</b>. Captured durations are metadata discovery, not user latency.</p></article>)}</div>
        </section>}

        {report.visibleSections.roadmap && <section id="roadmap" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">07 · Implementation roadmap</p><h2>Measure, pilot, then promote.</h2></div></div>
          <div className="roadmap">{report.roadmap.map((item, index) => <article key={item.wave}><span>{String(index + 1).padStart(2,"0")}</span><div><h3>{item.wave}</h3><p>{item.focus}</p><b>{item.outcome}</b></div></article>)}</div>
        </section>}

        {report.visibleSections.validation && <section id="validation" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">08 · Validation gate</p><h2>Tuning selesai hanya setelah terbukti.</h2></div></div>
          <div className="validation-card"><ol>{report.validation.map((item) => <li key={item}>{item}</li>)}</ol><div className="decision"><span>Acceptance decision</span><b>PROMOTE</b><b>REVISE</b><b>ROLLBACK</b></div></div>
        </section>}

        {report.visibleSections.custom && report.customBlocks.length > 0 && <section id="custom" className="section print-page">
          <div className="section-title"><div><p className="eyebrow">09 · Custom notes</p><h2>Additional assessment context.</h2></div></div>
          <div className="custom-grid">{report.customBlocks.map((block) => <article key={block.id}><h3>{block.title}</h3><p>{block.body}</p></article>)}</div>
        </section>}

        <footer><span>{report.meta.evidenceSet}</span><span>Generated from editable local report data</span></footer>
      </div>

      <div className="float-actions no-print">
        <button className="float-btn secondary" onClick={() => { setJsonDraft(JSON.stringify(report, null, 2)); setCustomizeOpen(true); }} aria-label="Customize report"><EditIcon/><span>Customize</span></button>
        <button className="float-btn primary" onClick={() => window.print()} aria-label="Export PDF A4"><PrintIcon/><span>Export PDF · A4</span></button>
      </div>

      {customizeOpen && <div className="drawer-backdrop no-print" onMouseDown={(e) => e.currentTarget === e.target && setCustomizeOpen(false)}>
        <aside className="drawer">
          <div className="drawer-head"><div><p className="eyebrow">Report controls</p><h2>Customize assessment</h2></div><button onClick={() => setCustomizeOpen(false)} aria-label="Close">×</button></div>
          <div className="drawer-body">
            <div className="control-group"><label>Report title<input value={report.meta.title} onChange={(e) => setReport({ ...report, meta: { ...report.meta, title: e.target.value } })}/></label><label>Subtitle<textarea rows={2} value={report.meta.subtitle} onChange={(e) => setReport({ ...report, meta: { ...report.meta, subtitle: e.target.value } })}/></label></div>
            <div className="control-group"><h3>Visible sections</h3>{Object.entries(sectionLabels).map(([id,label]) => <label className="switch-row" key={id}><span>{label}</span><input type="checkbox" checked={Boolean(report.visibleSections[id])} onChange={() => toggleSection(id)}/></label>)}</div>
            <div className="control-group"><div className="json-title"><div><h3>Edit full report JSON</h3><p>Add/remove candidates, coverage rows, roadmap items, or custom blocks.</p></div></div><textarea className="json-editor" spellCheck={false} value={jsonDraft} onChange={(e) => setJsonDraft(e.target.value)}/>{jsonError && <p className="json-error">{jsonError}</p>}</div>
          </div>
          <div className="drawer-actions"><button onClick={reset}>Reset default</button><button className="apply" onClick={applyJson}>Apply JSON</button></div>
        </aside>
      </div>}
    </main>
  );
}

function PrintIcon() { return <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 8V3h10v5M7 17H5a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2M7 14h10v7H7z"/></svg>; }
function EditIcon() { return <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 20h9M16.5 3.5a2.12 2.12 0 0 1 3 3L8 18l-4 1 1-4z"/></svg>; }
