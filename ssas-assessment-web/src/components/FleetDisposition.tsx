"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import type { FleetModel } from "@/types/report";

type FleetFilter = "ALL" | FleetModel["disposition"];

export default function FleetDisposition({ fleet, evidenceSet }: { fleet: FleetModel[]; evidenceSet: string }) {
  const [fleetFilter, setFleetFilter] = useState<FleetFilter>("ALL");
  const [fleetSearch, setFleetSearch] = useState("");

  const dispositionCounts = useMemo(() => ({
    DEEP_DIVE: fleet.filter((item) => item.disposition === "DEEP_DIVE").length,
    WATCHLIST: fleet.filter((item) => item.disposition === "WATCHLIST").length,
    MONITOR: fleet.filter((item) => item.disposition === "MONITOR").length,
    MULTIDIMENSIONAL_REVIEW: fleet.filter((item) => item.disposition === "MULTIDIMENSIONAL_REVIEW").length,
  }), [fleet]);

  const visibleFleet = useMemo(() => fleet
    .filter((item) => fleetFilter === "ALL" || item.disposition === fleetFilter)
    .filter((item) => item.database.toLowerCase().includes(fleetSearch.trim().toLowerCase()))
    .sort((a, b) => (b.score ?? -1) - (a.score ?? -1) || a.database.localeCompare(b.database)),
  [fleet, fleetFilter, fleetSearch]);

  return (
    <main>
      <aside className="rail no-print">
        <Link className="brand" href="/"><span>SA</span><b>SSAS<br/>Assessment</b></Link>
        <nav><Link href="/">← Assessment utama</Link><a href="#fleet">Daftar seluruh model</a><Link href="/glossary">Glosarium →</Link><Link href="/scoring">Simulator scoring →</Link></nav>
        <div className="rail-foot"><span className="live-dot"/> Evidence tersedia</div>
      </aside>

      <div className="report-shell" id="top">
        <section id="fleet" className="section fleet-page">
          <div className="section-title"><div><p className="eyebrow">04 · Daftar seluruh model</p><h2>Seluruh {fleet.length} model tetap tercakup dalam assessment.</h2></div><p className="section-note">Deep dive adalah urutan investigasi awal, bukan satu-satunya model yang dinilai. Watchlist dan monitoring tetap dipertahankan sampai sinyal runtime atau dampak bisnis menaikkan prioritas.</p></div>
          <div className="disposition-grid print-avoid">
            <button className={fleetFilter === "ALL" ? "active" : ""} onClick={() => setFleetFilter("ALL")}><strong>{fleet.length}</strong><span>Semua model</span></button>
            <button className={fleetFilter === "DEEP_DIVE" ? "active" : ""} onClick={() => setFleetFilter("DEEP_DIVE")}><strong>{dispositionCounts.DEEP_DIVE}</strong><span>Deep dive</span></button>
            <button className={fleetFilter === "WATCHLIST" ? "active" : ""} onClick={() => setFleetFilter("WATCHLIST")}><strong>{dispositionCounts.WATCHLIST}</strong><span>P1 watchlist</span></button>
            <button className={fleetFilter === "MONITOR" ? "active" : ""} onClick={() => setFleetFilter("MONITOR")}><strong>{dispositionCounts.MONITOR}</strong><span>Monitoring fleet</span></button>
            <button className={fleetFilter === "MULTIDIMENSIONAL_REVIEW" ? "active" : ""} onClick={() => setFleetFilter("MULTIDIMENSIONAL_REVIEW")}><strong>{dispositionCounts.MULTIDIMENSIONAL_REVIEW}</strong><span>Review MD</span></button>
          </div>
          <div className="fleet-tools no-print"><input type="search" value={fleetSearch} onChange={(event) => setFleetSearch(event.target.value)} placeholder="Cari database..."/><span>Menampilkan {visibleFleet.length} model</span></div>
          <div className="fleet-table-wrap"><table className="fleet-table"><thead><tr><th>Database</th><th>Tipe</th><th>Score</th><th>Risiko</th><th>Prioritas</th><th>Status tindak lanjut</th><th>Tabel</th><th>Kolom</th><th>Used MB*</th><th>Cakupan runtime</th></tr></thead><tbody>{visibleFleet.map((item) => <tr key={`${item.modelType}-${item.database}`}><td><b>{item.database}</b></td><td>{item.modelType === "MULTIDIMENSIONAL" ? "MD" : "Tabular"}</td><td>{item.score ?? "—"}</td><td><span className={`badge ${item.risk === "INFORMATIONAL" ? "neutral" : `risk-${item.risk.toLowerCase()}`}`}>{item.risk}</span></td><td>{item.priority}</td><td><span className={`disposition disposition-${item.disposition.toLowerCase()}`}>{item.disposition.replaceAll("_", " ")}</span></td><td>{item.tables}</td><td>{item.columns}</td><td>{item.usedMb || "—"}</td><td>{item.runtimeCoverage.replaceAll("_", " ")}</td></tr>)}</tbody></table></div>
          <p className="table-footnote">* Perhitungan DMV digunakan untuk ranking relatif, bukan sebagai ukuran authoritative resident memory. MONITOR tidak berarti sehat atau bebas finding; status tersebut berarti model belum dipilih untuk delapan deep dive awal.</p>
        </section>
        <footer><span>{evidenceSet}</span><span>Daftar seluruh model yang dinilai</span></footer>
      </div>
    </main>
  );
}
