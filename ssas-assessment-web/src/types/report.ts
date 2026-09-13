export type Risk = "CRITICAL" | "HIGH" | "MEDIUM" | "LOW";

export type Coverage = {
  area: string;
  status: "COMPLETE" | "PARTIAL" | "MISSING" | "UNSUPPORTED" | "SKIPPED";
  note: string;
};

export type Candidate = {
  rank: number;
  database: string;
  score: number;
  risk: Risk;
  priority: "P0" | "P1" | "P2" | "P3";
  status: string;
  runtimeExecutions: number;
  runtimeTotalMs: number;
  runtimeP95Ms: number | null;
  runtimeMaxMs: number | null;
  tables: number;
  columns: number;
  measures: number;
  relationships: number | null;
  partitions: number;
  usedMb: number;
  dictionaryMb: number;
  maxRows: number;
  classifications: string[];
  signals: string[];
  action: string;
  validation: string;
};

export type CustomBlock = {
  id: string;
  title: string;
  body: string;
};

export type FleetModel = {
  database: string;
  modelType: "TABULAR" | "MULTIDIMENSIONAL";
  score: number | null;
  risk: Risk | "INFORMATIONAL";
  priority: "P0" | "P1" | "P2" | "P3";
  disposition: "DEEP_DIVE" | "WATCHLIST" | "MONITOR" | "MULTIDIMENSIONAL_REVIEW";
  tables: number;
  columns: number;
  measures: number;
  usedMb: number;
  runtimeCoverage: string;
};

export type ReportData = {
  meta: {
    title: string;
    subtitle: string;
    evidenceSet: string;
    assessmentDate: string;
    confidentiality: string;
  };
  summary: {
    fleetScore: number;
    fleetRisk: Risk;
    tabularDatabases: number;
    multidimensionalDatabases: number;
    successfulArtifacts: number;
    failedUnsupported: number;
    skippedArtifacts: number;
    capturedBusinessQueries: number;
    multidimensionalQueries: number;
  };
  coverage: Coverage[];
  candidates: Candidate[];
  multidimensional: Array<{
    database: string;
    score: number;
    risk: Risk;
    priority: string;
    partitions: number;
    attributes: number;
    runtimeCoverage: string;
    capturedQueries: number;
    businessQueries: number;
  }>;
  roadmap: Array<{ wave: string; focus: string; outcome: string }>;
  validation: string[];
  fleet: FleetModel[];
  customBlocks: CustomBlock[];
  visibleSections: Record<string, boolean>;
};
