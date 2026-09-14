import PageNav from "@/components/PageNav";
import ScoringSimulator from "@/components/ScoringSimulator";

export default function ScoringPage() {
  return <main className="min-h-screen bg-[#f6f8f5] text-[#17241f]">
    <PageNav />
    <div className="lg:ml-[210px]">
    <header className="border-b border-[#dfe6e2] px-5 py-14 sm:px-8 lg:py-20"><div className="mx-auto max-w-7xl"><p className="text-xs font-extrabold uppercase tracking-[.2em] text-[#167d72]">Contoh interaktif</p><h1 className="mt-4 font-[family-name:var(--font-display)] text-5xl font-extrabold tracking-[-.05em] sm:text-7xl">Simulator scoring</h1><p className="mt-5 max-w-3xl text-base leading-7 text-[#66736e]">Ubah nilai lima kategori untuk melihat weighted score, label risiko, dan prioritas. Simulasi ini menjelaskan mekanisme prioritas relatif—bukan memprediksi latency.</p></div></header>
    <section className="mx-auto max-w-7xl px-5 pt-12 sm:px-8">
      <div className="border border-[#dfe6e2] bg-white p-6 sm:p-8">
        <p className="text-xs font-extrabold uppercase tracking-[.15em] text-[#167d72]">Asal bobot persentase</p>
        <h2 className="mt-2 font-[family-name:var(--font-display)] text-3xl font-extrabold">Normalisasi metodologi karena operational evidence belum merata</h2>
        <p className="mt-4 max-w-4xl text-sm leading-7 text-[#66736e]">Kontrak metodologi menetapkan bobot awal: Complexity 20%, Storage 25%, Partition 15%, Relationship 15%, Static DAX 15%, dan Operational 10%. Operational Risk tidak diberi nilai karena evidence runtime per database tidak tersedia secara representatif. Sesuai aturan “jangan membuat score untuk evidence yang tidak tersedia”, komponen 10% dikeluarkan dan lima bobot yang tersisa dinormalisasi dari total 90% menjadi 100%.</p>
        <div className="mt-7 grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
          {[['Complexity','20 ÷ 90','22.22%'],['Storage','25 ÷ 90','27.78%'],['Partition','15 ÷ 90','16.67%'],['Relationship','15 ÷ 90','16.67%'],['Static DAX','15 ÷ 90','16.67%']].map(([name, formula, result]) => <div key={name} className="border-l-4 border-[#167d72] bg-[#f4f7f5] p-4"><span className="block text-xs font-bold text-[#66736e]">{name}</span><code className="my-2 block text-xs">{formula} × 100</code><strong className="font-[family-name:var(--font-display)] text-2xl">{result}</strong></div>)}
        </div>
        <p className="mt-6 border-l-4 border-[#e98b3b] bg-[#fff4e8] p-4 text-xs leading-6 text-[#70441f]"><b>Penting:</b> bobot menunjukkan kontribusi kategori terhadap <i>priority score</i>, bukan kontribusi terhadap latency, CPU, atau memory. Runtime hanya dipakai sebagai sinyal deep-dive sampai representativitas workload dapat divalidasi.</p>
      </div>
    </section>
    <section className="mx-auto max-w-7xl px-5 pt-8 sm:px-8">
      <div className="grid gap-6 border border-[#dfe6e2] bg-white p-6 sm:p-8 lg:grid-cols-[.8fr_1.2fr]">
        <div><p className="text-xs font-extrabold uppercase tracking-[.15em] text-[#167d72]">Asal category score</p><h2 className="mt-2 font-[family-name:var(--font-display)] text-3xl font-extrabold">Contoh Relationship = 60</h2><p className="mt-4 text-sm leading-7 text-[#66736e]">Angka pada slider adalah <i>category score</i> 0–100. Dalam report sebenarnya nilai ini dihitung generator dari posisi relatif database terhadap 54 model Tabular dan indikator struktur yang ditemukan.</p></div>
        <div className="bg-[#f4f7f5] p-5 sm:p-7">
          <code className="block overflow-x-auto text-xs font-bold leading-6 text-[#0d584f]">RelationshipScore = ROUND(0.70 × P_RelationshipCount + MIN(30, 10 × Bidirectional + 10 × ManyToMany))</code>
          <div className="mt-5 grid gap-3 sm:grid-cols-3"><div className="bg-white p-4"><span className="text-xs text-[#66736e]">Relationship percentile</span><b className="mt-2 block text-xl">71.3</b></div><div className="bg-white p-4"><span className="text-xs text-[#66736e]">Bidirectional</span><b className="mt-2 block text-xl">1 × 10</b></div><div className="bg-white p-4"><span className="text-xs text-[#66736e]">Many-to-many</span><b className="mt-2 block text-xl">0 × 10</b></div></div>
          <p className="mt-5 text-sm leading-7"><b>ROUND(0.70 × 71.3 + 10) = ROUND(59.91) = 60</b></p>
          <div className="mt-4 space-y-3 text-xs leading-6 text-[#66736e]">
            <p><b>Mengapa 70%?</b> Ini heuristic desain assessment, bukan angka yang ditemukan dari pengukuran latency. Maksimal 70 poin dialokasikan untuk posisi jumlah relationship terhadap fleet, sedangkan maksimal 30 poin untuk indikator struktur bidirectional/many-to-many.</p>
            <p><b>Contoh percentile pada 54 model:</b> database yang dinilai memiliki misalnya 12 relationship; 36 model memiliki kurang dari 12, dan 5 model—termasuk database tersebut—sama-sama memiliki 12. Maka <code>(36 + 0,5 × 5) ÷ 54 × 100 = 71,3</code>.</p>
            <p>“Di bawah” berarti jumlah relationship-nya lebih kecil dari database yang dinilai. “Bernilai sama” berarti jumlah relationship-nya persis sama; tie memperoleh setengah credit agar model-model dengan nilai identik mendapat percentile yang sama. Relationship inactive dicatat sebagai evidence, tetapi tidak menambah formula score saat ini.</p>
          </div>
        </div>
      </div>
    </section>
    <ScoringSimulator />
    </div>
  </main>;
}
