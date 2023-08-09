import * as d3 from "d3";

// Copyright 2021 Observable, Inc.
// Released under the ISC license.
// https://observablehq.com/@d3/force-directed-graph
export default function buildGraph(
  {
    nodes, // an iterable of node objects (typically [{id}, …])
    links, // an iterable of link objects (typically [{source, target}, …])
  },
  {
    nodeId = (d) => d.id, // given d in nodes, returns a unique identifier (string)
    nodeGroup, // given d in nodes, returns an (ordinal) value for color
    nodeTitle, // given d in nodes, a title string
    nodeMetadata = (d) => d.metadata,
  } = {}
) {
  // Define constants
  const width = 1000;
  const height = 800;

  // Compute values.
  const N = d3.map(nodes, nodeId).map(intern);
  const LS = d3.map(links, ({ source }) => source).map(intern);
  const LT = d3.map(links, ({ target }) => target).map(intern);
  const T = d3.map(nodes, nodeTitle);
  const D = d3.map(nodes, nodeGroup);
  const G = normalize(d3.map(nodes, nodeGroup).map(intern));
  const M = d3.map(nodes, nodeMetadata);

  // Replace the input nodes and links with mutable objects for the simulation.
  nodes = d3.map(nodes, (_, i) => ({ id: N[i] }));
  links = d3.map(links, (_, i) => ({ source: LS[i], target: LT[i] }));

  // Construct the forces.
  const forceNode = d3.forceManyBody().strength(-800);
  const forceLink = d3.forceLink(links).id(({ index: i }) => N[i]);

  const simulation = d3
    .forceSimulation(nodes)
    .force("link", forceLink)
    .force("charge", forceNode)
    .force("center", d3.forceCenter())
    .on("tick", ticked);

  const svg = d3
    .create("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("viewBox", [-width / 2, -height / 2, width, height])
    .attr("style", "max-width: 100%; height: auto; height: intrinsic;");

  let zoomableGroup = svg.append("g").attr("class", "everything");
  const zoom = d3
    .zoom()
    .scaleExtent([0.5, 20])
    .on("zoom", (e) => {
      zoomableGroup.attr("transform", e.transform);
    });

  // call & disable zoom on double click
  svg.call(zoom).on("dblclick.zoom", null);

  const link = zoomableGroup
    .append("g")
    .attr("stroke-opacity", 0.3)
    .attr("stroke-width", 1.5)
    .attr("stroke-linecap", "round")
    .selectAll("line")
    .data(links)
    .join("line");

  const node = zoomableGroup
    .append("g")
    .selectAll("circle")
    .data(nodes)
    .join("circle")
    .attr("r", 6)
    .style("cursor", "pointer")
    .on("click", clicked)
    .call(drag(simulation))
    .style("stroke", "black")
    .style("stroke-width", ".5px")
    .style("fill", ({ index: i }) => d3.interpolateRdYlGn(G[i]));
  node.append("title").text(({ index: i }) => T[i]);

  var texts = zoomableGroup
    .selectAll("text.label")
    .data(nodes)
    .enter()
    .append("text")
    .style("user-select", "none")
    .style("font-size", "12px")
    .style("stroke", "black")
    .style("stroke-width", ".4px")
    .attr("class", "label")
    .attr("fill", ({ index: i }) => d3.interpolateRdYlGn(G[i]))
    .text(({ index: i }) => T[i]);

  function intern(value) {
    return value !== null && typeof value === "object"
      ? value.valueOf()
      : value;
  }

  function clicked(event) {
    const index = event.target.__data__.index;
    document.getElementById("name").innerHTML = N[index];
    document.getElementById("dependencies").innerHTML = D[index];
    if (M[index]["README"]) {
      document.getElementById("readme").style.display = "block";
      document.getElementById("readmelink").href = M[index]["README"];
    }
  }

  function ticked() {
    link
      .attr("x1", (d) => d.source.x)
      .attr("y1", (d) => d.source.y)
      .attr("x2", (d) => d.target.x)
      .attr("y2", (d) => d.target.y)
      .attr("stroke", (d) => d3.interpolateRdYlGn(G[d.source.index]));

    texts.attr("transform", (d) => `translate(${d.x + 6}, ${d.y + 6})`);
    node.attr("cx", (d) => d.x).attr("cy", (d) => d.y);
  }

  function drag(simulation) {
    function dragstarted(event) {
      if (!event.active) simulation.alphaTarget(0.1).restart();
      event.subject.fx = event.subject.x;
      event.subject.fy = event.subject.y;
    }

    function dragged(event) {
      event.subject.fx = event.x;
      event.subject.fy = event.y;
    }

    function dragended(event) {
      if (!event.active) simulation.alphaTarget(0);
      event.subject.fx = null;
      event.subject.fy = null;
    }

    return d3
      .drag()
      .on("start", dragstarted)
      .on("drag", dragged)
      .on("end", dragended);
  }

  function normalize(groups) {
    const min = Math.min(...groups);
    const max = Math.max(...groups);
    const scale = d3.scaleSymlog().domain([max, min]).range([0, 1]);
    return groups.map((group) => scale(group));
  }

  d3.select("g").selectAll("*").remove();
  d3.select("g").append(function () {
    return svg.node();
  });
}
