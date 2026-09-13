# SSAS Assessment Web

Interactive, editable web version of the evidence-driven SSAS assessment.

## Stack

- Next.js 16.3.5 (App Router; requirement was Next.js 15+)
- React 19.3
- ApexCharts 7.3 with `react-apexcharts`
- Native browser print pipeline with A4-specific CSS

Node.js 20.9 or later is required by current Next.js. The project was built with Node.js 24.

## Run locally

```powershell
cd .\ssas-assessment-web
npm install
npm run dev
```

Open `http://localhost:3000`.

## Customize the report

There are two supported paths:

1. Edit `src/data/assessment.json` for version-controlled default content.
2. Use the floating **Customize** button. You can change title/subtitle, hide sections,
   or edit the entire JSON to add/remove candidates, coverage, roadmap, validation, and
   custom blocks. Browser changes persist in `localStorage`; **Reset default** restores
   the source JSON.

Example custom block:

```json
{
  "id": "owner-notes",
  "title": "Owner decision",
  "body": "Add approved scope, maintenance window, or business context here."
}
```

## Export PDF A4

Use the floating **Export PDF · A4** button. In the browser print dialog select
**Save as PDF**, A4 portrait, default margins, and enable background graphics when the
browser does not preserve them automatically.

Print CSS hides navigation and controls, fixes A4 margins, constrains charts, and avoids
page breaks inside candidate cards, charts, metrics, and roadmap items. Always inspect
the preview after adding long custom content because user-added text can change pagination.

## Update assessment evidence

Update `src/data/assessment.json` from the repository reports. Do not insert unsupported
latency, FE/SE, refresh, memory, or usage claims. Preserve the `OBSERVED`, `INFERRED`,
`REQUIRES VALIDATION`, and `NOT PROVABLE FROM CURRENT EVIDENCE` boundaries.
