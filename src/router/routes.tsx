import { createBrowserRouter } from "react-router-dom";
import { App } from "../App";
import { GameMenu } from "../modules/menu/Menu";
import { FirstLevel } from "../modules/normal-game/first-level/first-level";

export const blastArenaRoutes = createBrowserRouter([
  {
    path: "/",
    element: <App />,
    children: [
      {
        path: "menu",
        element: <GameMenu />,
      },
      {
        path: "first-level",
        element: <FirstLevel />,
      },
    ],
  },
]);
