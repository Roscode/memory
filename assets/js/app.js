// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"; // eslint-disable-line no-unused-vars

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html";
import $ from "jquery";

// Import local files
//
// Local files can be imported directly using relative paths, for example:
import socket from "./socket";

import game_init from "./memory";

$(() => {
  let root = $("#root")[0];
  if (root) {
    let name = window.location.pathname.split("/").pop();
    let channel = socket.channel(`games:${name}`, {});
    game_init(root, channel);
  }
  else {
    $("#game-name-input").on("change", function({target: {value: name}}) {
      $("#join-game-button").attr("href", `/game/${name}`);
    });
  }
});
