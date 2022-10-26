const NodeDetails = () => {
  return (
    <div
      style={{
        width: 200,
        height: 400,
        marginRight: "1em",
        backgroundColor: "white",
        borderRadius: "0.4rem",
        border: "0.1rem solid #dcdcdc",
        padding: "1em",
        overflow: "wrap",
        fontSize: "10px",
      }}
    >
      <div style={{ fontSize: "14px", marginBottom: "1em" }}>
        <b>Pack Information</b>
      </div>
      <div
        style={{
          display: "flex",
          flexDirection: "column",
        }}
      >
        <div>Name: </div>
        <div id="name" style={{ marginBottom: "1em" }}></div>
        <div># of Dependencies: </div>
        <div id="dependencies" style={{ marginBottom: "1em" }}></div>
        <div id="readme" style={{ display: "none" }}>
          <a href="/" id="readmelink" target="_blank">
            README
          </a>
        </div>
      </div>
    </div>
  );
};

export default NodeDetails;
