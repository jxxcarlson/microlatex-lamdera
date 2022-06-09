/* elm-pkg-js
port playChirp : Cmd msg
*/

exports.init = async function init(app) {
  app.ports.playChirp.subscribe( function() {
   console.log("Starting play-chirp");
   var audio = new Audio('boing-short.mp3');
   audio.play();
  })
}

