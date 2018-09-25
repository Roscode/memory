import React from "react";
import ReactDOM from "react-dom";
import _ from "lodash";

export default function game_init(root) {
  ReactDOM.render(<Memory />, root);
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
        if (!completed) onClick();
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

const getInitialState = () => ({
  tiles: randomBoard(),
  guesses: [],
  partialGuess: null,
  delay: null
});

export class Memory extends React.Component {
  constructor(props) {
    super(props);
    this.state = getInitialState();
  }

  tileClicked(x, y) {
    const { partialGuess, guesses, tiles, delay } = this.state;
    if (partialGuess) {
      const [px, py] = partialGuess;
      const newGuess = [partialGuess, [x, y]];
      const isCorrect =
        _.get(tiles, [y, x, "letter"]) === _.get(tiles, [py, px, "letter"]);
      const setTileState = tile =>
        Object.assign({}, tile, {
          visible: false,
          completed: isCorrect
        });
      const onEnd = () =>
        this.setState({
          tiles: _(tiles)
            .update([y, x], setTileState)
            .update([py, px], setTileState)
            .value(),
          delay: null
        });
      const timer = setTimeout(onEnd, 1500);
      this.setState({
        partialGuess: null,
        guesses: [newGuess, ...guesses],
        tiles: _.set(tiles, [y, x, "visible"], true),
        delay: { onEnd, timer }
      });
    } else {
      if (delay) {
        const { onEnd, timer } = delay;
        clearTimeout(timer);
        onEnd();
      }
      this.setState({
        partialGuess: [x, y],
        tiles: _.set(tiles, [y, x, "visible"], true)
      });
    }
  }

  youWin() {
    return _.reduce(
      this.state.tiles,
      (outerAcc, row) => {
        return (
          outerAcc &&
          _.reduce(
            row,
            (acc, { completed }) => {
              return acc && completed;
            },
            true
          )
        );
      },
      true
    );
  }

  getScore() {
    const { guesses, partialGuess } = this.state;
    return 2 * guesses.length + (_.isNull(partialGuess) ? 0 : 1);
  }

  render() {
    const {
      tileClicked,
      state: { tiles }
    } = this;
    const winnerMessage = this.youWin() ? (
      `You Win! Your final score was: ${this.getScore()}`
    ) : (
      <Score score={this.getScore()} />
    );
    const onRestart = () => this.setState(getInitialState);
    return (
      <div className="memory">
        <h1>The Game of Memory</h1>
        <Board tiles={tiles} onTileClicked={tileClicked.bind(this)} />
        {winnerMessage}
        <Restart onRestart={onRestart} />
      </div>
    );
  }
}
