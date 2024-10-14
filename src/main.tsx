import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import { blastArenaRoutes } from "./router/routes.tsx";
import { RouterProvider } from "react-router-dom";


const routes = blastArenaRoutes

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <RouterProvider router={routes}></RouterProvider>
  </StrictMode>
);
