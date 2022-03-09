module MicroLaTeX.Parser.Block exposing (..)


{-|
    indent: number of leading spaces in the first line of the block
    lineNumber: index of the first line of the block in the source
    content: the body of bhe block
    numberOfLines: the number of lines in the body
    name: the name of the block if it has one.  This is determined
          by the first line of the block.  In L0, if the first line is
          "| FOO ..." or "|| FOO ..." then the name is Just FOO
          In microLaTeX, if the first line is "\begin{FOO} ..."
          then the name is FOO.  If the first line does not begin
          with "|", "||" or "\begin{", the name is Nothing
          and the block is a paragraph
   args: again depends only on the first line.  It is the block
         is a paragraph, then args = [].  In L0, if the first line
         is "| FOO BAR BAZ .." or "|| FOO BAR BAZ.." the args = [BAR, BAZ, ...].
         In microLaTeX, if the first line is  "\begin{FOO}", then args = [].
         If it is "\begin{FOO}[BAR][BAZ]..." then args = [BAR, BAZ, ...].
-}
type alias RawBlock =
    { indent : Int
    , lineNumber : Int
    , content : List String
    , numberOfLines : Int
    , name : Maybe String
    , args : List String
    }



type SM
    = SM { state : State, register : Register }


type State
    = Start
    | InBlock RawBlock
    | Error

type alias Register  { lineNumber : Int, numberOfLines: Int, lines : List String, blocks : List RawBlock}

runSM : List String -> SM
runSM lines =
    let
        folder : String -> SM -> SM
        folder =
                   \line sm -> nextState line sm
    in
    List.foldl folder (initializeSM lines) lines


initializeSM : List String -> SM
initializeSM lines =
  let
      register =  { lineNumber = 0, numberOfLines = List.length lines, lines = lines, blocks = [] }
  in
  SM { state = Start, register = register}



nextState : String -> SM -> SM
nextState line (SM {state, register} as sm) =
    case state of
        Start ->
            nextStateAtStart line sm

        InBlock _ ->
            nextStateInBlock line sm

        Error ->
            sm

