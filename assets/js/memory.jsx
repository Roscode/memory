import React from "react";
import ReactDOM from "react-dom";
import _ from "lodash";

export default function game_init(root, channel) {
  ReactDOM.render(<Memory channel={channel} />, root);
}

export const LETTERS = "AABBCCDDEEFFGGHH".split("");

export function randomBoard() {
  const base = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]];
  const availableLetters = _.shuffle(LETTERS);
  return _.map(base, row =>
    _.map(row, () => ({
      letter: availableLetters.pop(),
      completed: false,
      visible: false
    }))
  );
}

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

export const Score = ({ score }) => <p>Your score is: {score}</p>;

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
      .receive("ok", ({ game }) => {
        this.setState({ game: JSON.parse(game) });
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
    const winnerMessage = won ? (
      `You Win! Your final score was: ${score}`
    ) : (
      <Score score={score} />
    );
    const onRestart = () => {
      this.channel
        .push("restart")
        .receive("ok", ({ game }) => this.setState({ game }));
    };
    return (
      <div className="memory">
        <Board tiles={tiles} onTileClicked={tileClicked.bind(this)} />
        {winnerMessage}
        <Restart onRestart={onRestart} />
      </div>
    );
  }
}
