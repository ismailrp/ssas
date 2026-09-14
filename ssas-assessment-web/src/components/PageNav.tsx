import Link from "next/link";

const links = [
  ["/", "Assessment"],
  ["/fleet", "Daftar seluruh model"],
  ["/findings", "Dokumen findings"],
  ["/glossary", "Glosarium"],
  ["/scoring", "Simulator scoring"],
];

export default function PageNav() {
  return (
    <>
      <aside className="fixed inset-y-0 left-0 z-20 hidden w-[210px] flex-col bg-[#102f2b] px-[22px] py-7 text-[#dfece8] lg:flex print:hidden">
        <Link href="/" className="mb-11 flex items-center gap-3">
          <span className="grid size-[42px] place-items-center border border-[#6ba69e] font-[family-name:var(--font-display)] font-extrabold text-white">SA</span>
          <b className="font-[family-name:var(--font-display)] text-[13px] leading-[1.15] tracking-wide">SSAS<br/>Assessment</b>
        </Link>
        <nav className="flex flex-col gap-2" aria-label="Navigasi utama">
          {links.map(([href, label]) => <Link key={href} href={href} className="border-l-2 border-transparent px-[10px] py-[9px] text-xs text-[#a9c1ba] transition hover:border-[#e9a263] hover:bg-[#173b36] hover:text-white">{label}</Link>)}
        </nav>
        <div className="mt-auto flex items-center gap-2 text-[11px] text-[#9fb8b1]"><span className="size-[7px] rounded-full bg-[#54d2a5] shadow-[0_0_0_4px_rgba(84,210,165,.1)]"/>Halaman pendukung</div>
      </aside>
      <nav className="border-b border-white/10 bg-[#102f2b] px-5 py-4 text-white lg:hidden print:hidden" aria-label="Navigasi mobile">
        <Link href="/" className="font-[family-name:var(--font-display)] text-sm font-extrabold">SSAS Assessment</Link>
        <div className="mt-3 flex flex-wrap gap-1 text-xs font-bold text-[#bcd2cc]">{links.map(([href, label]) => <Link key={href} href={href} className="rounded-full px-3 py-2 hover:bg-white/10 hover:text-white">{label}</Link>)}</div>
      </nav>
    </>
  );
}
