import React from "react";
import ReactDOM from "react-dom";
import _ from "lodash";

export default function game_init(root, channel) {
  ReactDOM.render(<Memory channel={channel} />, root);
}

export const LETTERS = "AABBCCDDEEFFGGHH".split("");

// A board is a 4x4 grid of buttons
// with x being left->right 0->3 and y being top->bottom 0->3
export const Board = ({ tiles, onTileClicked }) => (
  <table>
    <tbody>
      {_.map(tiles, (tileRow, y) => (
        <tr key={y}>
          {_.map(tileRow, (tile, x) => (
            <Tile {...tile} onClick={() => onTileClicked(x, y)} key={x} />
          ))}
        </tr>
      ))}
    </tbody>
  </table>
);

export const Tile = ({ letter, completed, onClick, visible }) => (
  <td>
    <button
      onClick={() => {
        if (!completed && !visible) onClick();
      }}
    >
      {completed ? "yay" : visible ? letter : "?"}
    </button>
  </td>
);

export const Restart = ({ onRestart }) => (
  <button onClick={onRestart}>Restart</button>
);

export class Memory extends React.Component {
  constructor(props) {
    super(props);
    this.channel = props.channel;
    this.state = { loading: true };
    this.channel
      .join()
      .receive("ok", ({ game }) =>
        this.setState({ loading: false, game: JSON.parse(game) })
      )
      .receive("error", resp => {
        console.log("Unable to join", resp); // eslint-disable-line no-console
      });
  }

  tileClicked(x, y) {
    this.channel
      .push("guess", { x, y })
      .receive("ok", ({ game: raw, temp }) => {
        const game = JSON.parse(raw);
        this.setState({ game });
        if (temp) {
          window.setTimeout(
            () =>
              this.channel
                .push("get")
                .receive("ok", ({ game: raw }) =>
                  this.setState({ game: JSON.parse(raw) })
                ),
            1500
          );
        }
      })
      .receive("error", r => console.log(r)); // eslint-disable-line no-console
  }

  render() {
    const {
      tileClicked,
      state: { loading, game }
    } = this;
    if (loading) return <div>Joining the game...</div>;
    const { tiles, score, won } = game;
    const onRestart = () => {
      this.channel
        .push("restart")
        .receive("ok", ({ game }) => this.setState({ game: JSON.parse(game) }));
    };
    return (
      <div className="memory">
        <Board tiles={tiles} onTileClicked={tileClicked.bind(this)} />
        <p>
          {won
            ? `You Win! You final score was: ${score}`
            : `You score is: ${score}`}
        </p>
        <Restart onRestart={onRestart} />
      </div>
    );
  }
}
