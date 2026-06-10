import express from "express";
const app = express();
app.get("/health", (_req, res) => res.send("OK"));
app.listen(3000);
