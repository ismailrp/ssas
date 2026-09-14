"use client";

import { useMemo, useState } from "react";

const categories = [
  { id: "complexity", label: "Complexity", weight: 22.22, note: "Tables, columns, measures, hierarchies, roles, dan calculated objects." },
  { id: "storage", label: "Storage", weight: 27.78, note: "Fleet-relative USED_SIZE, dictionary, segment, dan row concentration." },
  { id: "partition", label: "Partition", weight: 16.67, note: "Kombinasi skala tabel, jumlah partition, dan source/boundary evidence." },
  { id: "relationship", label: "Relationship", weight: 16.67, note: "Jumlah, cardinality, active state, serta filter direction." },
  { id: "dax", label: "Static DAX", weight: 16.67, note: "Static pattern hits; tidak membuktikan Formula Engine bottleneck." },
] as const;

type CategoryId = typeof categories[number]["id"];
const initial: Record<CategoryId, number> = { complexity: 55, storage: 80, partition: 70, relationship: 35, dax: 50 };

function classify(score: number) {
  if (score >= 80) return { risk: "CRITICAL", priority: "P0", color: "#b83232" };
  if (score >= 60) return { risk: "HIGH", priority: "P1", color: "#d87524" };
  if (score >= 30) return { risk: "MEDIUM", priority: "P2", color: "#b38716" };
  return { risk: "LOW", priority: "P3", color: "#167d72" };
}

export default function ScoringSimulator() {
  const [values, setValues] = useState(initial);
  const contributions = useMemo(() => categories.map(item => ({ ...item, contribution: values[item.id] * item.weight / 100 })), [values]);
  const score = contributions.reduce((total, item) => total + item.contribution, 0);
  const result = classify(score);

  return <div className="mx-auto grid max-w-7xl gap-8 px-5 py-12 sm:px-8 lg:grid-cols-[1.35fr_.65fr] lg:py-16">
    <section className="border border-[#dfe6e2] bg-white p-6 sm:p-8">
      <div className="mb-8 flex flex-wrap items-end justify-between gap-3"><div><p className="text-xs font-extrabold uppercase tracking-[.15em] text-[#167d72]">Category inputs</p><h2 className="mt-2 font-[family-name:var(--font-display)] text-3xl font-extrabold">Contoh model</h2></div><button onClick={() => setValues(initial)} className="cursor-pointer border border-[#cbd6d1] bg-white px-4 py-2 text-xs font-bold hover:border-[#167d72]">Reset example</button></div>
      <div className="space-y-8">{categories.map(item => <div key={item.id}><div className="mb-3 flex items-start justify-between gap-5"><div><label htmlFor={item.id} className="text-sm font-extrabold">{item.label} <span className="font-normal text-[#66736e]">({item.weight.toFixed(2)}%)</span></label><p className="mt-1 max-w-2xl text-xs leading-5 text-[#66736e]">{item.note}</p></div><output className="min-w-14 bg-[#e8f2ef] px-3 py-2 text-center font-[family-name:var(--font-display)] text-lg font-extrabold text-[#0d584f]">{values[item.id]}</output></div><input id={item.id} type="range" min="0" max="100" step="1" value={values[item.id]} onChange={event => setValues(current => ({ ...current, [item.id]: Number(event.target.value) }))} className="h-2 w-full cursor-pointer accent-[#167d72]" /></div>)}</div>
    </section>
    <aside className="space-y-6">
      <section className="sticky top-6 bg-[#123d37] p-7 text-white shadow-[0_22px_60px_rgba(25,47,40,.16)] sm:p-9"><p className="text-xs font-extrabold uppercase tracking-[.16em] text-[#9ed1c7]">Weighted result</p><div className="my-7 flex items-end gap-3"><strong className="font-[family-name:var(--font-display)] text-7xl font-extrabold leading-none">{score.toFixed(1)}</strong><span className="pb-2 text-sm text-[#bcd2cc]">/ 100</span></div><div className="flex gap-2"><span className="rounded-full px-4 py-2 text-xs font-extrabold text-white" style={{ backgroundColor: result.color }}>{result.risk}</span><span className="rounded-full border border-white/25 px-4 py-2 text-xs font-extrabold">{result.priority}</span></div><div className="mt-8 border-t border-white/15 pt-6"><p className="text-xs leading-6 text-[#cce1dc]">Formula: jumlah dari <b>category score × normalized weight</b>. Operational/runtime score dikeluarkan ketika evidence per database tidak tersedia.</p></div></section>
      <section className="border border-[#dfe6e2] bg-white p-6"><h3 className="font-[family-name:var(--font-display)] text-lg font-extrabold">Contribution detail</h3><div className="mt-4 divide-y divide-[#e7ece9]">{contributions.map(item => <div key={item.id} className="flex justify-between gap-4 py-3 text-xs"><span className="text-[#66736e]">{item.label}: {values[item.id]} × {item.weight.toFixed(2)}%</span><b>{item.contribution.toFixed(2)}</b></div>)}</div></section>
      <div className="border-l-4 border-[#e98b3b] bg-[#fff4e8] p-5 text-xs leading-6 text-[#70441f]"><b>Interpretation gate:</b> score memprioritaskan investigasi. Root cause, latency, dan benefit tuning tetap <b>NOT PROVABLE FROM CURRENT EVIDENCE</b> sampai divalidasi.</div>
    </aside>
  </div>;
}
