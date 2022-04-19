module Token exposing (get)

import Random exposing (Seed, initialSeed, step)
import Random.Char
import Random.Int
import Random.String
import Uuid


get : Random.Seed -> { token : String, seed : Random.Seed }
get seed_ =
    let
        ( newUuid, newSeed ) =
            step Uuid.uuidGenerator seed_
    in
    { token = Uuid.toString newUuid, seed = newSeed }


getOld : Random.Seed -> { token : String, seed : Random.Seed }
getOld seed_ =
    let
        { words, seed } =
            randomWords seed_ 2 6

        ( digits, newSeed ) =
            Random.step (Random.Int.intGreaterThan 1000000) seed

        digitString =
            String.fromInt digits

        a =
            String.left 5 digitString

        b =
            String.left 5 (String.dropLeft 5 digitString)

        token =
            List.map2 (\alpha num -> String.left 4 alpha ++ num) words [ a, b ] |> String.join "-"
    in
    { token = token, seed = newSeed }


randomWords : Random.Seed -> Int -> Int -> { words : List String, seed : Random.Seed }
randomWords seed n wordLength =
    loop
        { words = []
        , seed = seed
        , wordLength = wordLength
        , wordsToMake = n
        }
        nextState


type alias State =
    { words : List String
    , seed : Random.Seed
    , wordLength : Int
    , wordsToMake : Int
    }


nextState : State -> Step State { words : List String, seed : Random.Seed }
nextState state =
    if state.wordsToMake == 0 then
        Done { words = state.words, seed = state.seed }

    else
        let
            ( newWord, newSeed ) =
                Random.step (Random.String.string state.wordLength Random.Char.lowerCaseLatin) state.seed
        in
        Loop { state | wordsToMake = state.wordsToMake - 1, words = newWord :: state.words, seed = newSeed }


type Step state a
    = Loop state
    | Done a


loop : state -> (state -> Step state a) -> a
loop s nextState_ =
    case nextState_ s of
        Loop s_ ->
            loop s_ nextState_

        Done b ->
            b
