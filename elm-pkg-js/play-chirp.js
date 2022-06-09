/* elm-pkg-js
port play_chirp : Cmd msg
*/

exports.init = async function init(app) {
  app.ports.playChirp.subscribe( function() {
   console.log("Starting play-chirp");
   var audio = new Audio('chirp.mp3');
   audio.play();
  })
}

