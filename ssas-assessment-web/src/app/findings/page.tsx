import fs from "node:fs";
import path from "node:path";
import PageNav from "@/components/PageNav";

const findingsDirectory = path.join(process.cwd(), "public", "findings");

function formatBytes(bytes: number) {
  return `${new Intl.NumberFormat("id-ID", { maximumFractionDigits: 1 }).format(bytes / 1024)} KB`;
}

export default function FindingsPage() {
  const files = fs.existsSync(findingsDirectory)
    ? fs.readdirSync(findingsDirectory)
      .filter((name) => name.toLowerCase().endsWith(".docx"))
      .map((name) => ({ name, size: fs.statSync(path.join(findingsDirectory, name)).size, example: name.startsWith("CONTOH PENGISIAN") }))
      .sort((a, b) => Number(a.example) - Number(b.example) || a.name.localeCompare(b.name))
    : [];

  return <main className="min-h-screen bg-[#f6f8f5] text-[#17241f]">
    <PageNav />
    <div className="lg:ml-[210px]">
      <header className="bg-gradient-to-br from-[#123d37] to-[#187064] px-5 py-16 text-white sm:px-8 lg:py-24">
        <div className="mx-auto max-w-7xl"><p className="text-xs font-extrabold uppercase tracking-[.2em] text-[#9ed1c7]">Dokumen temuan</p><h1 className="mt-4 max-w-4xl font-[family-name:var(--font-display)] text-5xl font-extrabold tracking-[-.05em] sm:text-7xl">Dokumen temuan SSAS</h1><p className="mt-6 max-w-2xl text-base leading-7 text-[#cce1dc]">Dokumen dapat diunduh dan diedit. Setiap rekomendasi tetap harus divalidasi sebelum perubahan diterapkan.</p></div>
      </header>
      <section className="mx-auto max-w-7xl px-5 py-12 sm:px-8 lg:py-16">
        <div className="mb-7 flex flex-wrap items-end justify-between gap-3"><div><p className="text-xs font-extrabold uppercase tracking-[.15em] text-[#167d72]">Daftar file</p><h2 className="mt-2 font-[family-name:var(--font-display)] text-3xl font-extrabold">{files.length} dokumen tersedia</h2></div><p className="max-w-xl text-xs leading-6 text-[#66736e]">File berlabel CONTOH PENGISIAN berisi angka ilustratif dan bukan hasil pengukuran aktual.</p></div>
        <div className="grid gap-3">
          {files.map((file) => <a key={file.name} href={`/findings/${encodeURIComponent(file.name)}`} download className="group grid gap-3 border border-[#dfe6e2] bg-white p-5 transition hover:border-[#167d72] hover:shadow-[0_8px_28px_rgba(29,49,43,.08)] sm:grid-cols-[1fr_auto] sm:items-center"><div><div className="flex flex-wrap items-center gap-2"><h3 className="font-[family-name:var(--font-display)] text-base font-extrabold">{file.name.replace(/\.docx$/i, "")}</h3>{file.example && <span className="rounded-full bg-[#fff0c9] px-2 py-1 text-[9px] font-extrabold text-[#876118]">CONTOH</span>}</div><p className="mt-1 text-xs text-[#66736e]">Microsoft Word · {formatBytes(file.size)}</p></div><span className="text-xs font-extrabold text-[#167d72] group-hover:underline">Unduh DOCX ↓</span></a>)}
          {files.length === 0 && <p className="border border-[#dfe6e2] bg-white p-6 text-sm text-[#66736e]">Belum ada DOCX yang dipublikasikan.</p>}
        </div>
      </section>
    </div>
  </main>;
}
