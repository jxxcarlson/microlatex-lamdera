module Debounce exposing
    ( Debounce, Msg
    , Config, init
    , Strategy, soon, soonAfter, later, manual, manualAfter
    , Send, takeLast, takeAll
    , update, push, unlock
    )

{-| The Debouncer. See the full example [here](https://github.com/jinjor/elm-debounce/blob/master/examples/Main.elm).

  - This module works with the Elm Architecture.
  - You can choose the strategy and define how commands are sent.


# Types

@docs Debounce, Msg


# Initialize

@docs Config, init


# Strategies

@docs Strategy, soon, soonAfter, later, manual, manualAfter


# Sending Commands

@docs Send, takeLast, takeAll


# Update

@docs update, push, unlock

-}

import Duration
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Process
import Effect.Task exposing (..)


{-| The state of the debouncer.

It is parameterized with the value type `a`.

-}
type Debounce a
    = Debounce
        { input : List a
        , locked : Bool
        }


length : Debounce a -> Int
length (Debounce { input }) =
    List.length input


{-| Config contains the debouncing strategy and the message transformation.

This config should be constant and shared between `update` function and `push` function.

-}
type alias Config msg =
    { strategy : Strategy
    , transform : Msg -> msg
    }


{-| Strategy defines the timing when commands are sent.
-}
type Strategy
    = Manual Float
    | Soon Float Float
    | Later Float


{-| Send command as soon as it gets ready, with given rate limit. (a.k.a. Throttle)

Note: The first command will be sent immidiately.

-}
soon : Float -> Strategy
soon =
    Soon 0


{-| Similar to `soon`, but the first command is sent after offset time.
-}
soonAfter : Float -> Float -> Strategy
soonAfter =
    Soon


{-| Send command after becomming stable, with given delay time. (a.k.a. Debounce)
-}
later : Float -> Strategy
later =
    Later


{-| Send command as soon as it gets ready, but not again until it gets unlocked manually. See `unlock`.

Typically, `unlock` is called after previous response comes back.

-}
manual : Strategy
manual =
    Manual 0


{-| Similar to `manual`, but the first command is sent after offset time.
-}
manualAfter : Float -> Strategy
manualAfter =
    Manual


{-| This function consumes values and send a command.

If you want to postpone sending, return the values back to keep them.

-}
type alias Send a msg toMsg =
    a -> List a -> ( List a, Command FrontendOnly toMsg msg )


{-| Send a command using the latest value.
-}
takeLast : (a -> Command FrontendOnly toMsg msg) -> Send a msg toMsg
takeLast send head tail =
    ( [], send head )


{-| Send a command using all the accumulated values.
-}
takeAll : (a -> List a -> Command FrontendOnly toMsg msg) -> Send a msg toMsg
takeAll send head tail =
    ( [], send head tail )


{-| Initialize the debouncer. Call this from your `init` function.
-}
init : Debounce a
init =
    Debounce
        { input = []
        , locked = False
        }


{-| The messages that are used internally.
-}
type Msg
    = NoOp
    | Flush (Maybe Float)
    | SendIfLengthNotChangedFrom Int


{-| This is the component's update function following the Elm Architecture.

e.g. Saving the last value.

    ( debounce, cmd ) =
        Debounce.update
            { strategy = Debounce.later (1 * second)
            , transform = DebounceMsg
            }
            (Debounce.takeLast save)
            -- save : value -> Cmd Msg
            msg
            model.debounce

The config should be constant and shared with `push` function.

The sending logic can depend on the current model. If you want to stop sending, return `Cmd.none`.

-}
update : Config msg -> Send a msg toMsg -> Msg -> Debounce a -> ( Debounce a, Command FrontendOnly toMsg msg )
update config send msg (Debounce d) =
    case msg of
        NoOp ->
            ( Debounce d
            , Command.none
            )

        Flush tryAgainAfter ->
            case d.input of
                head :: tail ->
                    let
                        ( input, sendCmd ) =
                            send head tail

                        selfCmd =
                            case tryAgainAfter of
                                Just delay ->
                                    delayCmd delay (Flush (Just delay))

                                Nothing ->
                                    Command.none
                    in
                    ( Debounce
                        { d
                            | input = input
                            , locked = True
                        }
                    , Command.batch [ sendCmd, Command.map identity config.transform selfCmd ]
                    )

                _ ->
                    ( Debounce { d | locked = False }
                    , Command.none
                    )

        SendIfLengthNotChangedFrom lastInputLength ->
            case ( List.length d.input <= lastInputLength, d.input ) of
                ( True, head :: tail ) ->
                    let
                        ( input, cmd ) =
                            send head tail
                    in
                    ( Debounce { d | input = input }
                    , cmd
                    )

                _ ->
                    ( Debounce d
                    , Command.none
                    )


{-| Manually unlock. This works for `manual` or `manualAfter` Strategy.
-}
unlock : Config msg -> Command FrontendOnly toMsg msg
unlock config =
    Command.map identity config.transform <|
        Effect.Task.perform
            identity
            (Effect.Task.succeed (Flush Nothing))


{-| Push a value into the debouncer.
-}
push : Config msg -> a -> Debounce a -> ( Debounce a, Command FrontendOnly toMsg msg )
push config a (Debounce d) =
    let
        newDebounce =
            Debounce { d | input = a :: d.input }

        selfCmd : Command FrontendOnly toMsg Msg
        selfCmd =
            case config.strategy of
                Manual offset ->
                    if d.locked then
                        Command.none

                    else
                        delayCmd offset (Flush Nothing)

                Soon offset delay ->
                    if d.locked then
                        Command.none

                    else
                        delayCmd offset (Flush (Just delay))

                Later delay ->
                    delayCmd delay (SendIfLengthNotChangedFrom (length newDebounce))
    in
    ( newDebounce, Command.map identity config.transform selfCmd )


delayCmd : Float -> msg -> Command FrontendOnly toMsg msg
delayCmd delay msg =
    Effect.Task.perform (\_ -> msg) (Effect.Process.sleep (Duration.milliseconds delay))
