import type { ReactNode } from "react";

function inline(text: string): ReactNode[] {
  const normalized = text
    .replace(/Deep-Dive Recommendation/gi, "Prioritas Tindak Lanjut")
    .replace(/deep[- ]dive/gi, "analisis lanjutan")
    .replace(/fleet-relative/gi, "relatif terhadap seluruh model")
    .replace(/\bfleet\b/gi, "seluruh model");
  return normalized.split(/(\*\*[^*]+\*\*|`[^`]+`)/g).filter(Boolean).map((part, index) => {
    if (part.startsWith("**") && part.endsWith("**")) return <strong key={index}>{part.slice(2, -2)}</strong>;
    if (part.startsWith("`") && part.endsWith("`")) return <code key={index}>{part.slice(1, -1)}</code>;
    return part;
  });
}

const cells = (line: string) => line.trim().replace(/^\||\|$/g, "").split("|").map((value) => value.trim());
const isDivider = (line: string) => cells(line).every((value) => /^:?-{3,}:?$/.test(value));

export default function MarkdownReport({ content }: { content: string }) {
  const lines = content.replace(/\r\n/g, "\n").split("\n");
  const output: ReactNode[] = [];
  let index = 0;

  while (index < lines.length) {
    const line = lines[index].trim();
    if (!line) { index++; continue; }

    if (line.startsWith("|") && index + 1 < lines.length && isDivider(lines[index + 1])) {
      const headers = cells(line);
      const rows: string[][] = [];
      index += 2;
      while (index < lines.length && lines[index].trim().startsWith("|")) { rows.push(cells(lines[index])); index++; }
      output.push(<div className="model-detail-table-wrap" key={`table-${index}`}><table className="model-detail-table"><thead><tr>{headers.map((value, cellIndex) => <th key={cellIndex}>{inline(value)}</th>)}</tr></thead><tbody>{rows.map((row, rowIndex) => <tr key={rowIndex}>{row.map((value, cellIndex) => <td key={cellIndex}>{inline(value)}</td>)}</tr>)}</tbody></table></div>);
      continue;
    }

    const heading = /^(#{1,6})\s+(.+)$/.exec(line);
    if (heading) {
      const level = Math.min(heading[1].length + 1, 6);
      const Tag = `h${level}` as keyof React.JSX.IntrinsicElements;
      output.push(<Tag key={`heading-${index}`}>{inline(heading[2])}</Tag>);
      index++;
      continue;
    }

    if (/^[-*]\s+/.test(line)) {
      const items: string[] = [];
      while (index < lines.length && /^[-*]\s+/.test(lines[index].trim())) { items.push(lines[index].trim().replace(/^[-*]\s+/, "")); index++; }
      output.push(<ul key={`list-${index}`}>{items.map((item, itemIndex) => <li key={itemIndex}>{inline(item)}</li>)}</ul>);
      continue;
    }

    const paragraph = [line];
    index++;
    while (index < lines.length && lines[index].trim() && !/^(#{1,6})\s+/.test(lines[index].trim()) && !lines[index].trim().startsWith("|") && !/^[-*]\s+/.test(lines[index].trim())) { paragraph.push(lines[index].trim()); index++; }
    output.push(<p key={`paragraph-${index}`}>{inline(paragraph.join(" "))}</p>);
  }

  return <article className="model-detail-content">{output}</article>;
}
