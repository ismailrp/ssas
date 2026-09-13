import AssessmentDashboard from "@/components/AssessmentDashboard";
import assessment from "@/data/assessment.json";
import fleet from "@/data/fleet.json";
import type { ReportData } from "@/types/report";

export default function Home() {
  return <AssessmentDashboard initialData={{ ...assessment, fleet } as ReportData} />;
}
