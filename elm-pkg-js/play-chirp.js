/* elm-pkg-js
port playChirp : Cmd msg
*/

exports.init = async function init(app) {
  app.ports.playSound.subscribe( function(filename) {
   console.log("Starting play-chirp");
   var audio = new Audio(filename);
   audio.play();
  })
}

