import { Outlet } from "react-router-dom";
import "./App.css";

export function App() {
  return (
    <>
      <div id="divisior">
        <Outlet />
      </div>
    </>
  );
}
