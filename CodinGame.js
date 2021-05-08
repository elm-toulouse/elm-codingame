// Concatenate above the compiled file Elm.js obtained from
// elm make Main.elm --optimize --output=Elm.js

// Retrieve initial data from input.
const numberOfCells = parseInt(readline()); // 37
let cells = [];
for (let i = 0; i < numberOfCells; i++) {
    var inputs = readline().split(' ');
    const index = parseInt(inputs[0]); // 0 is the center cell, the next cells spiral outwards
    const richness = parseInt(inputs[1]); // 0 if the cell is unusable, 1-3 for usable cells

    cells.push({ index, richness });

    const neigh0 = parseInt(inputs[2]); // the index of the neighbouring cell for each direction
    const neigh1 = parseInt(inputs[3]);
    const neigh2 = parseInt(inputs[4]);
    const neigh3 = parseInt(inputs[5]);
    const neigh4 = parseInt(inputs[6]);
    const neigh5 = parseInt(inputs[7]);
}

const flags =
  { numberOfCells
  , cells
  };

// Init Elm app with initial data.
const app = this.Elm.Main.init({ flags });

// Setup subscription to elm outgoing port
// used to transfer the string to print.
app.ports.stdout.subscribe((cmd) => console.log(cmd));

// We can also setup an error port for debug.
app.ports.stderr.subscribe((msg) => console.error(msg));

// Start the game loop.
gameLoop();

// Game loop.
function gameLoop() {
  // Send game turn data to elm for processing.
  app.ports.stdin.send(readLinesIntoTurnData());

  // Give up priority on the event loop to enable
  // subscription to elm outgoing port to trigger.
  setTimeout(gameLoop, 0);
}

// Update turnData with the new turn data.
// Performs side effects (readline)
function readLinesIntoTurnData() {
  // The index of the node on which the Skynet agent is positioned this turn.
  const day = parseInt(readline()); // the game lasts 24 days: 0-23
  const nutrients = parseInt(readline()); // the base score you gain from the next COMPLETE action

  var inputs = readline().split(' ');
  const me = {
    sun: parseInt(inputs[0]), // your sun points
    score: parseInt(inputs[1]), // your current score
    asleep: false
  };

  var inputs = readline().split(' ');
  const other = {
    sun: parseInt(inputs[0]),
    score: parseInt(inputs[1]),
    asleep: inputs[2] !== '0'
  };


  const numberOfTrees = parseInt(readline()); // the current amount of trees

  let trees = [];
  for (let i = 0; i < numberOfTrees; i++) {
      var inputs = readline().split(' ');
      const index = parseInt(inputs[0]); // location of this tree
      const size = parseInt(inputs[1]); // size of this tree: 0-3
      const isMine = inputs[2] !== '0'; // 1 if this is your tree
      const isDormant = inputs[3] !== '0'; // 1 if this tree is dormant
      trees.push({ index, size, isMine, isDormant });
  }

  const numberOfPossibleActions = parseInt(readline()); // all legal actions
  let possibleActions = [];
  for (let i = 0; i < numberOfPossibleActions; i++) {
      possibleActions.push(readline()); // try printing something from here to start with
  }

  return { day, nutrients, me, other, numberOfTrees, trees, numberOfPossibleActions, possibleActions }
}
