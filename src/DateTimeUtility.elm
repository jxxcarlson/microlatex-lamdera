module DateTimeUtility exposing (toString, toStringWithYear)

import Time exposing (Month(..), toDay, toHour, toMonth, toYear, utc)


toString : Time.Zone -> Time.Posix -> String
toString zone time =
    monthString (Time.toMonth zone time)
        ++ "/"
        ++ (String.fromInt (Time.toDay zone time) |> String.padLeft 2 '0')
        --++ "/"
        --++ String.fromInt (Time.toYear zone time)
        ++ ", "
        ++ (String.fromInt (toHour zone time) |> String.padLeft 2 '0')
        ++ ":"
        ++ (String.fromInt (Time.toMinute zone time) |> String.padLeft 2 '0')


toStringWithYear : Time.Zone -> Time.Posix -> String
toStringWithYear zone time =
    monthString (Time.toMonth zone time)
        ++ "/"
        ++ (String.fromInt (Time.toDay zone time) |> String.padLeft 2 '0')
        ++ "/"
        ++ String.fromInt (Time.toYear zone time)
        ++ ", "
        ++ (String.fromInt (toHour zone time) |> String.padLeft 2 '0')
        ++ ":"
        ++ (String.fromInt (Time.toMinute zone time) |> String.padLeft 2 '0')



--


monthString : Time.Month -> String
monthString month =
    case month of
        Jan ->
            "1"

        Feb ->
            "2"

        Mar ->
            "3"

        Apr ->
            "4"

        May ->
            "5"

        Jun ->
            "6"

        Jul ->
            "7"

        Aug ->
            "8"

        Sep ->
            "9"

        Oct ->
            "10"

        Nov ->
            "11"

        Dec ->
            "12"
