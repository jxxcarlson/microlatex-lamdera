/* elm-pkg-js
port play_chirp : Cmd msg
*/

exports.init = async function init(app) {
  app.ports.play_chirp.subscribe(async function() {
   var audio = new Audio('chirp.mp3');
   audio.play();
  })
}

