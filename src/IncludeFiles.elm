module IncludeFiles exposing (getData)


type alias State =
    { input : List String, output : List String }


getData : String -> List String
getData str =
    let
        lines =
            String.lines str
    in
    case List.head lines of
        Nothing ->
            []

        Just firstLine ->
            if firstLine == "|| load-files" then
                getLinesUntilEmptyLine (List.drop 1 lines)

            else
                []


getLinesUntilEmptyLine : List String -> List String
getLinesUntilEmptyLine lines =
    loop { input = lines, output = [] } nextStep |> List.reverse


nextStep : State -> Step State (List String)
nextStep state =
    case List.head state.input of
        Nothing ->
            Done state.output

        Just line ->
            if line == "" then
                Done state.output

            else
                Loop { state | input = List.drop 1 state.input, output = line :: state.output }


type Step state a
    = Loop state
    | Done a


loop : state -> (state -> Step state a) -> a
loop s f =
    case f s of
        Loop s_ ->
            loop s_ f

        Done b ->
            b
