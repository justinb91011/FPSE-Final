// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Game from "./components/Game.res.mjs";
import * as StartBackground from "./components/StartBackground.res.mjs";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptReactRouter from "@rescript/react/src/RescriptReactRouter.res.mjs";

function App(props) {
  var url = RescriptReactRouter.useUrl(undefined, undefined);
  var match = url.path;
  if (!match) {
    return JsxRuntime.jsx(StartBackground.make, {});
  }
  if (match.hd === "game") {
    var match$1 = match.tl;
    if (match$1 && !match$1.tl) {
      return JsxRuntime.jsx(Game.make, {
                  difficulty: match$1.hd
                });
    }
    
  }
  return JsxRuntime.jsx("div", {
              children: "Page Not Found"
            });
}

var make = App;

export {
  make ,
}
/* Game Not a pure module */
