import React from "react";
import ReactDOM from "react-dom";
import _ from "lodash";

export default function game_init(root, channel) {
  ReactDOM.render(<Memory channel={channel} />, root);
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

export const Restart = ({ show, onRestart }) =>
  show ? <button onClick={onRestart}>Restart</button> : null;

export const ScoreBoard = ({ players, turn }) =>
  _.map(players, player => (
    <div>
      <p>Player: {player}</p>
      {player == turn ? <p>"Active"</p> : null}
    </div>
  ));

export const ActiveGame = ({
  tiles,
  winner,
  players,
  turn,
  tileClicked,
  onRestart
}) => (
  <div className="memory">
    <ScoreBoard players={players} turn={turn} />
    <Board tiles={tiles} onTileClicked={tileClicked.bind(this)} />
    <Restart show={!!winner} onRestart={onRestart} />
  </div>
);

export const Lobby = ({ joinGame }) => (
  <div className="memory">
    <button onClick={joinGame} />
  </div>
);

export class Memory extends React.Component {
  constructor(props) {
    super(props);
    this.channel = props.channel;
    this.state = { loading: true };
    this.channel.on("update", ({ game: raw }) =>
      this.setState({ game: JSON.parse(raw) })
    );
    this.channel
      .join()
      .receive("ok", ({ game: raw }) =>
        this.setState({ loading: false, game: JSON.parse(raw) })
      )
      .receive("error", resp => {
        console.log("Unable to join", resp); // eslint-disable-line no-console
      });
  }

  tileClicked(x, y) {
    this.channel.push("flip", { x, y });
  }

  render() {
    const {
      tileClicked,
      state: { loading, game }
    } = this;
    if (loading) return <div>Joining the game...</div>;
    const { inProgress } = game;
    const onRestart = () => this.channel.push("restart");
    const joinGame = () => this.channel.push("join");
    return (
      <div className="memory">
        {inProgress ? (
          <ActiveGame
            {...game}
            onRestart={onRestart}
            tileClicked={tileClicked}
          />
        ) : (
          <Lobby joinGame={joinGame} />
        )}
      </div>
    );
  }
}
