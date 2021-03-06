module Backend.Cmd exposing (getRandomNumber)

import Effect.Command exposing (Command)
import Effect.Http
import Types exposing (BackendMsg(..))


getRandomNumber : Command restriction toMsg BackendMsg
getRandomNumber =
    Effect.Http.get
        { url = randomNumberUrl 9
        , expect = Effect.Http.expectString GotAtomsphericRandomNumber
        }


{-| maxDigits < 10
-}
randomNumberUrl : Int -> String
randomNumberUrl maxDigits =
    let
        maxNumber =
            10 ^ maxDigits

        prefix =
            "https://www.random.org/integers/?num=1&min=1&max="

        suffix =
            "&col=1&base=10&format=plain&rnd=new"
    in
    prefix ++ String.fromInt maxNumber ++ suffix



-- https://www.random.org/integers/?num=1&min=1&max=10000000000&col=1&base=10&format=plain&rnd=new
