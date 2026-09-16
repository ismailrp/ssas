import fs from "node:fs";
import path from "node:path";
import Link from "next/link";
import { notFound } from "next/navigation";
import PageNav from "@/components/PageNav";
import MarkdownReport from "@/components/MarkdownReport";
import { modelSlug } from "@/lib/modelSlug";

const reportsDirectory = path.join(process.cwd(), "src", "data", "model-reports");
const reportFiles = () => fs.readdirSync(reportsDirectory).filter((name) => name.toLowerCase().endsWith(".md"));

export function generateStaticParams() {
  return reportFiles().map((name) => ({ database: modelSlug(path.basename(name, ".md")) }));
}

export default async function ModelDetailPage({ params }: { params: Promise<{ database: string }> }) {
  const { database } = await params;
  const matchedFile = reportFiles().find((name) => modelSlug(path.basename(name, ".md")) === database);
  if (!matchedFile) notFound();
  const content = fs.readFileSync(path.join(reportsDirectory, matchedFile), "utf8");
  const modelName = path.basename(matchedFile, ".md");

  return <main className="min-h-screen bg-[#f6f8f5] text-[#17241f]">
    <PageNav />
    <div className="lg:ml-[210px]">
      <header className="model-detail-hero"><div className="mx-auto max-w-6xl"><Link href="/fleet" className="model-detail-back">← Kembali ke daftar model</Link><p className="model-detail-eyebrow">Technical assessment</p><h1>{modelName}</h1><p>Detail struktur, score, evidence, temuan, dan rekomendasi untuk model ini.</p></div></header>
      <section className="mx-auto max-w-6xl px-5 py-10 sm:px-8 lg:py-14"><MarkdownReport content={content} /></section>
    </div>
  </main>;
}
