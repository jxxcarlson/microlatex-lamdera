/* elm-pkg-js
port playSound : Cmd msg
*/

exports.init = async function init(app) {
  app.ports.playSound.subscribe( function(filename) {
   console.log("Starting play-sound");
   var audio = new Audio(filename);
   audio.play();
  })
}

