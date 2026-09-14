import FleetDisposition from "@/components/FleetDisposition";
import assessment from "@/data/assessment.json";
import fleet from "@/data/fleet.json";
import type { FleetModel } from "@/types/report";

export default function FleetPage() {
  return <FleetDisposition fleet={fleet as FleetModel[]} evidenceSet={assessment.meta.evidenceSet} />;
}
