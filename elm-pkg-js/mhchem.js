exports.init =  async function(app) {

     console.log("I am starting mhChem init");

     var mhChemJs = document.createElement('script')
     mhChemJs.type = 'text/javascript'
     mhChemJs.src = "https://cdn.jsdelivr.net/npm/katex@0.15.3/dist/contrib/mhchem.min.js"


     document.head.appendChild(mhChemJs);
     console.log("mhChem: I have appended mhChemJs to document.head");

}