import { useEffect } from "react";
import data from "../utilities/packwerk_graph.json";
import buildGraph from "../utilities/buildGraph.js";

const ForceGraph = () => {
  useEffect(() => {
    buildGraph(data, {
      nodeId: (d) => d.id,
      nodeGroup: (d) => d.group,
      nodeTitle: (d) => `${d.id}\n${d.group}`,
    });
  }, []);

  return (
    <svg
      width="1000"
      height="800"
      style={{
        backgroundColor: "white",
        borderRadius: "0.4rem",
        border: "0.1rem solid #dcdcdc",
      }}
    >
      <g />
    </svg>
  );
};

export default ForceGraph;
