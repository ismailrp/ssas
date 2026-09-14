import PageNav from "@/components/PageNav";

const groups = [
  { title: "Evidence & claims", terms: [
    ["OBSERVED", "Fakta yang ditunjukkan langsung oleh artifact evidence dan dapat ditelusuri ke file sumber."],
    ["INFERRED", "Indikasi kuat dari korelasi evidence, tetapi dampaknya belum diukur langsung."],
    ["REQUIRES VALIDATION", "Hipotesis yang masih memerlukan workload, Server Timings, processing log, atau eksperimen terkontrol."],
    ["Coverage", "Status ketersediaan evidence: COMPLETE, PARTIAL, MISSING, UNSUPPORTED, atau SKIPPED."],
    ["Evidence gap", "Data yang belum tersedia. Gap bukan bukti adanya masalah performa."],
  ]},
  { title: "Storage & model", terms: [
    ["USED_SIZE", "Ukuran yang dilaporkan DMV untuk membandingkan storage relatif; bukan total resident memory authoritative."],
    ["DICTIONARY_SIZE", "Ukuran dictionary encoding kolom. Nilai besar dapat menjadi kandidat review cardinality dan tipe data."],
    ["Segment", "Unit penyimpanan kolumnar VertiPaq yang membantu menilai distribusi row dan encoding."],
    ["Calculated column", "Kolom yang dihitung saat processing dan disimpan dalam model; berbeda dari measure yang dihitung saat query."],
    ["Partition", "Pembagian data tabel untuk mengatur scope processing dan pemeliharaan. Jumlah rendah tidak otomatis berarti buruk."],
  ]},
  { title: "Runtime & tuning", terms: [
    ["FE / Formula Engine", "Mesin yang menangani logika DAX, context transition, dan operasi yang tidak diselesaikan Storage Engine."],
    ["SE / Storage Engine", "Mesin yang melakukan scan dan agregasi pada storage VertiPaq atau sumber DirectQuery."],
    ["Warm run", "Eksekusi setelah cache terkait telah terisi; harus dibandingkan dalam kondisi yang konsisten."],
    ["Cold cache", "Pengujian tanpa cache relevan. Clear cache hanya dilakukan dengan approval dan window yang sesuai."],
    ["P95", "Persentil ke-95 durasi sampel; bermakna hanya jika sampel dan workload cukup representatif."],
    ["Static DAX risk", "Pola seperti iterator atau DISTINCTCOUNT yang layak diperiksa, tetapi bukan bukti query lambat."],
  ]},
  { title: "Priority & decision", terms: [
    ["P0–P3", "Urutan prioritas assessment berdasarkan score dan konteks; bukan label insiden ataupun bukti latency."],
    ["Confidence", "Tingkat keyakinan finding: HIGH, MEDIUM, atau LOW berdasarkan kekuatan dan kelengkapan evidence."],
    ["Semantic regression", "Validasi bahwa hasil bisnis tetap sama setelah perubahan model atau DAX."],
    ["Deep dive", "Investigasi terarah terhadap kandidat prioritas menggunakan query nyata dan evidence tambahan."],
  ]},
];

export default function GlossaryPage() {
  return <main className="min-h-screen bg-[#f6f8f5] text-[#17241f]">
    <PageNav />
    <div className="lg:ml-[210px]">
    <header className="bg-gradient-to-br from-[#123d37] to-[#187064] px-5 py-16 text-white sm:px-8 lg:py-24">
      <div className="mx-auto max-w-7xl"><p className="text-xs font-extrabold uppercase tracking-[.2em] text-[#9ed1c7]">Reference</p><h1 className="mt-4 max-w-4xl font-[family-name:var(--font-display)] text-5xl font-extrabold tracking-[-.05em] sm:text-7xl">SSAS assessment glossary</h1><p className="mt-6 max-w-2xl text-base leading-7 text-[#cce1dc]">Definisi ringkas untuk membaca evidence, score, finding, dan rencana validasi secara konsisten.</p></div>
    </header>
    <div className="mx-auto grid max-w-7xl gap-8 px-5 py-12 sm:px-8 lg:grid-cols-2 lg:py-16">
      {groups.map(group => <section key={group.title} className="border border-[#dfe6e2] bg-white p-6 shadow-[0_8px_28px_rgba(29,49,43,.05)] sm:p-8"><h2 className="mb-6 font-[family-name:var(--font-display)] text-2xl font-extrabold">{group.title}</h2><dl className="divide-y divide-[#e7ece9]">{group.terms.map(([term, definition]) => <div key={term} className="grid gap-2 py-5 sm:grid-cols-[150px_1fr] sm:gap-6"><dt className="text-sm font-extrabold text-[#167d72]">{term}</dt><dd className="m-0 text-sm leading-6 text-[#66736e]">{definition}</dd></div>)}</dl></section>)}
    </div>
    </div>
  </main>;
}
