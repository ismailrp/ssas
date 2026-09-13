"use client";

import dynamic from "next/dynamic";
import type { ApexAxisChartSeries, ApexOptions } from "apexcharts";

const Chart = dynamic(() => import("react-apexcharts"), { ssr: false });

type Props = {
  options: ApexOptions;
  series: ApexAxisChartSeries | number[];
  type: "bar" | "donut";
  height?: number;
};

export default function ApexChart({ options, series, type, height = 320 }: Props) {
  return <Chart options={options} series={series} type={type} height={height} width="100%" />;
}
